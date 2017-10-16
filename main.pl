#!/usr/bin/perl
use strict;

# Used by Generic_Command_Run() to detect status of last command.
sub Get_Error {
	my $lstext_status = "$?";    # Gets exit status of last running command.
	if ( !$lstext_status ) {
		return 1;                # Returns success
	}
	else {
		return 0;                # Returns error
	}
}

# Contacts the website http://cubemonkey.net/quotes/ to get a random quote!
# Don't worry - if contacting website fails, I do not abort the entire script! :D
sub GetQuote {	
	my $quote="\"Nu, pogodi!\", -Wolf"; # This is the default quote, in case retriving quote from internet fails.

	my $SuccessQuote=1;
	my $quotefile="myquote.html";

	# If any of the two command return error, getting a quote failed
	system("wget \"http://subfusion.net/cgi-bin/quote.pl?quote=cookie&number=1\" -O $quotefile -q");
	if (Get_Error() == 0 ) {
		$SuccessQuote=0; 
	}
	my $quotehtml=readpipe("cat $quotefile 2>&1 ");
	if ( Get_Error() == 0  ) {
		$SuccessQuote=0; 
	}

	if ($SuccessQuote != 0 ) { # Capturing the quote from the html file
		if ($quotehtml =~ m/<body><br><br><b><hr><br>\n((.|\n)*)<br><br><hr><br>/) {
			$quote=$1;
			#$quote=~s/\n/ /g; # Uncomment this if you want to remove \n from quote.)
		}
	}
	system("rm $quotefile"); # cleaning up
	return ("Quote of the Day:\n$quote");
}


# Used by Get_Parameter_Value()
sub RemoveWhitespace {
	$_[0] =~ s/\s+//;     #remove leading spaces
	$_[0] =~ s/\s+$//;    #remove trailing spaces
}

sub Email { 
	# Usage: Emails a message to user, depending on $params{email} state, and on $emailtype
	# emailtype=1 job is starting; emailtype=2 job is ending; emailtype=-1 error has occured. die() after email.
	# emailtype=0 success but don't email. (like when GC_Run() succeeds for example).
	# This function also aborts NewARQ in case of error, regardless of emailing

	my ($emailcode, %params ) = @_;	# getting emailcode and parameters of parameter file

	my $JbName = "$params{genname}$params{runnumber}";	# Job name
	if ( ($params{email} ne "") && (lc($params{email}) ne "none" ) ){	# Checks if user allowed emails
		my $message;	# message subject
		my $messageBody=readpipe("cat main"."$params{runnumber}".".log 2>&1 "); # message body includes main*.log (if everything is ok then it is SUCCESS all over. main*.log includes error details in case of error.
		if    ($emailcode == 1) {$message="Job $JbName\tSTART\tCounter=$params{counter}"; }
		elsif ($emailcode == 2) {$message="Job $JbName\tEND\tCounter=$params{counter}";   }
		elsif ($emailcode == -1){$message="Job $JbName\t**ERROR**\tCounter=$params{counter}";   }
		my $emailcmd=" echo -e \"$messageBody\" \| mail -s \"$message\" $params{email} ";

		# This system command is sent without logging it into main*.log since in case of error log file will have been closed already.
		system("$emailcmd") == 0 or die ("Failed to send email, $message\n$messageBody");
	}

	# Aborts on errorcode -1 regardless of emailing state. 
	if ($emailcode == -1) {die("NewARQ failed. Please check main$params{runnumber}.log file. \n");}
}


# Writes the next parameter file
sub Write_New_Param {

	# Usage: Write_New_Param (parameter-hash list);
	my ($newparam_filename, %params) = @_;
	my $JbName = "$params{genname}$params{runnumber}";

	# Advancing counters to next phase
	--$params{counter};
	if($params{counter} <= 0 ) {
		$params{counter}=0;	
	} 
	$params{starttime}+=($params{extend})/1000;
	++$params{runnumber};

	open( NewPARAM, ">$newparam_filename" );
	print NewPARAM "\#         ARQ Parameter File\t Version 2.01\n";
	print NewPARAM "\#-------------------------------------------------\n";
	print NewPARAM "\# Written by Shay Amram, Tel Aviv University, Faculty of Life Sciences, Department of Biochemistry\n";
	print NewPARAM "\# Email: shayamra\@post.tau.ac.il \n\# www.tau.ac.il/\~shayamra\n\n";
	foreach my $key ( keys(%params) ) {
		if ($key eq "resume") {
			print NewPARAM "$key=yes\n";	# when NewARQ writes new param.arq resume is set to "yes" by default.
		} else {
			print NewPARAM "$key=$params{$key}\n";
		}
	}
	print NewPARAM "\n\# Basic instructions for each field. Note that the field themselves are case-insensitive, but some of the values may be case-sesitive (filenames, etc.)\n";
	print NewPARAM "\# RunType: 'Hemi' (without quotes). You can use 'light' option for light queue.\n";
	print NewPARAM "\#          'Desktop' option runs of desktop computers. Tested for CentOS and Ununtu.\n";
	print NewPARAM "\# GenName: Prefix name for all files created by the simulations. This should also be the base-name of the first tpr file.\n";
	print NewPARAM "\#          For example GenName=Test means Test.tpr file must be at the same directory as NewARQ at initiation.\n";
	print NewPARAM "\#          NewARQ adds GenNames with RunNumber automatically. \n";
	print NewPARAM "\# NCPUS: Number of cpus. This number can be adjusted with each iteration. Immidiately after running NewARQ it will also create\n";
	print NewPARAM "\#        param.arq file to be used on the next iteration. Before the next iteration arrives, NCPUS value may be changed.\n";
	print NewPARAM "\# Nice: Nice Level. In cluster jobs nice is automatically set to 0. \n";
	print NewPARAM "\# RunNumber: Keeps track of how many iterations of ARQ were. Normally this should be set to 1 on the first iteration\n";
	print NewPARAM "\#            This number will be added as suffix to all simulation file names: GenName-RunNumber.\n";
	print NewPARAM "\# Email: If your system supports it, NewARQ may send notification email after each iteration is completed.\n";
	print NewPARAM "\#        If your system does not support mail, or you prefer to disable mail, please specify 'none'.\n";
	print NewPARAM "\# StartTime: Keeps track of total simulation time up-till-now. Normally this should be set to 0 on the first iteration\n";
	print NewPARAM "\#            ***Time is [ns]***.\n";
	print NewPARAM "\# Extend: ***Time in [ps]*** to extend simulation in each iteration. This is an adjustable parameter (See NCPUS).\n";
	print NewPARAM "\# Counter: This is the number of times (iterations) NewARQ will perform.\n";
	print NewPARAM "\# GromacsVer: This value can be 4 or 45 to use GROMACS 4.0.x or 4.5.x, respectively. \n";
	print NewPARAM "\#             Note that system environment must be set to use the proper version of GROMACS.\n";
	print NewPARAM "\# Resume: 'yes'/'no'. If a simulation stopped in the middle, 'yes' (default option) will use the .cpt file to resume the simulation.\n";
	print NewPARAM "\#         NOTE that you need to rename the .tpr file to be GenName.tpr *and* to make sure the other stuff in param.arq is correct (starttime, runnumber.. etc)\n";
	print NewPARAM "\#         Since version 2.x the script 'resume=yes' is default)\n";
	print NewPARAM "\n\n";


	close(NewPARAM);
	return 0;
}

# Running external OS commands. Returns success/error + writes log file.
sub GC_Run { # Generic Command Runner
# INPUT: Command line to be executed in terminal and Log File name. Assumes $LogFile is already opened for writing.
# OUTPUT: Writes to LOG_FILE the status of the command executed. 
#         On success, returns the output from the executed command. This is useful to capture all kinds of text (like the output of qsub, stating the JOB_ID)
	my $Get_Command = $_[0];
	my $LogFile     = $_[1];
	my $Run_Command = readpipe("$Get_Command 2>&1 ") ; # This magical command returns ALL of the output. Without the 2>&1 all the 'interactive' parts of the command will not be returned! Seriously, this is magic.
	if ( Get_Error() ) {
		# The {$LogFile} uses $LogFile as a file handler. That's a way to pass file handler between main program and sub.
		printf {$LogFile} "* SUCCESS: Command \"$Get_Command\" executed successfully. \n";
		return($Run_Command);	# On success return command output (will not cause email)
	} else {	# On error, the command output is written to logfile
		printf {$LogFile} "* ERROR: Command \"$Get_Command\" terminated with error.\nTerminating ARQ Cycle. \n";
		if ($Run_Command ne "") {
			printf {$LogFile} "\tError Command Output:\n$Run_Command \n";
		}
		my $Quote=GetQuote();
		printf {$LogFile} "\n-----------------------------------------------------\n$Quote\n\n";
		close($LogFile);
		return(-1);	# returns error (emails log-file).
	}
}

# Running qstat command. (the same as GC_Run, except it doesn't write to logfile, and returns output if error). 
sub QSTAT_Run { # qstat runner
# INPUT: qstat Command line to be executed in terminal.
# OUTPUT: On success, returns the output from qstat. This is useful to capture all kinds of text.
# Since we execute qstat a large number of times we don't write success/error for this command. Its only use is to track
# if the job is on queue, or not. Having fail simply means that it is no longer on queue. Other tests determine if the iteration was a success. 
	my $Get_Command = $_[0];
	my $Run_Command = readpipe("$Get_Command 2>&1 ") ; # This magical command returns ALL of the output. Without the 2>&1 all the 'interactive' parts of the command will not be returned! Seriously, this is magic.

	if ( Get_Error() ) { # on success return 0. We don't really care for the output of qstat, as long as job is in queue.
		return(0); 	
	} else {	# On error, return output (could be many different errors).
		return($Run_Command);	
	}
}

# Checks if job name starts with a letter. If it doesnt I add a "A_" prefix. (Cluster does not like job names that start with special characters)
sub CheckJobName {
	my $genname = $_[0];
	my $prefix="";
	if (!($genname =~ m/^[a-zA-Z]+/) ) {	# if the name does not start with a letter, return prefix A_
		$prefix="A_";
	}
	return("$prefix");
}

# Writes Queue file for (CLUSTER) queue system
sub Write_Queue {
	# Usage: Write_Queue (parameter-hash list);
	my (%params ) = @_;
	my $JbName = "$params{genname}$params{runnumber}";
	my $prefix=CheckJobName($params{genname}); # gives A_ prefix to job names that don't start with a letter (cluster doesn't like them)
	
	open( Queue, ">${JbName}.sge" ) or die("Could not open ${JbName}.sge for writing. Please make sure you have proper permissions.\n\n" );
	print Queue "\#\!\/bin\/csh\n";
	print Queue "\#\$ -N $prefix"."$params{genname}"."$params{runnumber}\n";
	print Queue "\#\$ -cwd\n";
	print Queue "\#\$ -pe mpich2_smpd $params{ncpus}\n";
	print Queue "module load mpich/mpich2_smpd\n";
	print Queue "smpd -s\n";
	print Queue "setenv MPIEXEC_RSH rsh\n";
	print Queue "setenv SMPD_OPTION_NO_DYNAMIC_HOST 1\n";
	print Queue "set HOST=\`cat \$PE_HOSTFILE\|awk -F. \'\{print \$1\}\'\`\n"; 	# should look like this: set HOST=`cat $PE_HOSTFILE|awk -F. '{print $1}'`
	print Queue "echo \$\{HOST\}:\$\{NSLOTS\}>hosts.\$JOB_ID\n"; 				# echo ${HOST}:${NSLOTS}>hosts.$JOB_ID
	print Queue "echo MPIEXEC=\`which mpiexec\`\n";
	print Queue "echo MPIRUN=\`which mpirun\`\n";

	# Choose GROMACS version
	if ($params{"gromacsver"} == 4){	# GROMACS 4.0.x
		print Queue "module load gromacs/gromacs407_smpd\n";
	} elsif ($params{"gromacsver"} == 45) {	# GROMACS 4.5.x
		print Queue "module load gromacs/gromacs453_smpd\n";	
	} 
	print Queue "echo MDRUN=\`which mdrun\`\n";
	print Queue "GMXRC\n";

	# The && in the end of the normal gromacs-command means that it will be executed ONLY if the the previous command has 
	# finished running **successfully**. main.pl tests to see when {JbName}.txt file has been created, which indicates the job ended.
	# This way when the job moves nodes/suspends the txt file is not created. I hope!
	# P.S. on the cluster we use nice 0 by default.

	print Queue "mpiexec -machinefile hosts.\$JOB_ID  -np \$NSLOTS  mdrun -v -nice 0 -cpt 1 -cpo ${JbName}.cpt -v -s ${JbName} -deffnm ${JbName} -np \$NSLOTS $params{resume} > ${JbName}.std && echo \"Job ${JbName} has been finished. You may erase this file.\" \>${JbName}.txt\n\n";
	print Queue "smpd -shutdown\n";
	print Queue "exit 0\n";
	close Queue;

}

# Writes Light Queue file for (CLUSTER) queue system
sub Write_Queue_Light {
	# Usage: Write_Queue (parameter-hash list);
	my (%params ) = @_;
	my $JbName = "$params{genname}$params{runnumber}";
	my $prefix=CheckJobName($params{genname}); # gives A_ prefix to job names that don't start with a letter (cluster doesn't like them)
	
	open( Queue, ">${JbName}.sge" ) or die("Could not open ${JbName}.sge for writing. Please make sure you have proper permissions.\n\n" );
	print Queue "\#\!\/bin\/csh\n";
	print Queue "\#\$ -N $prefix"."$params{genname}"."$params{runnumber}\n";
	print Queue "\#\$ -cwd\n";
	print Queue "\#\$ -ckpt BLCR\n";
	print Queue "\#\$ -pe mpich2_smpd $params{ncpus}\n";
	print Queue "module load mpich/mpich2_smpd\n";
	print Queue "smpd -s\n";
	print Queue "module load blcr/blcr-0.8.2\n";
	print Queue "setenv MPIEXEC_RSH rsh\n";
	print Queue "setenv SMPD_OPTION_NO_DYNAMIC_HOST 1\n";
	print Queue "set HOST=\`cat \$PE_HOSTFILE\|awk -F. \'\{print \$1\}\'\`\n"; 	# should look like this: set HOST=`cat $PE_HOSTFILE|awk -F. '{print $1}'`
	print Queue "echo \$\{HOST\}:\$\{NSLOTS\}>hosts.\$JOB_ID\n"; 				# echo ${HOST}:${NSLOTS}>hosts.$JOB_ID
	print Queue "echo MPIEXEC=\`which mpiexec\`\n";
	print Queue "echo MPIRUN=\`which mpirun\`\n";

	# Choose GROMACS version
	if ($params{"gromacsver"} == 4){	# GROMACS 4.0.x
		print Queue "module load gromacs/gromacs407_smpd\n";
	} elsif ($params{"gromacsver"} == 45) {	# GROMACS 4.5.x
		print Queue "module load gromacs/gromacs453_smpd\n";	
	} 
	print Queue "echo MDRUN=\`which mdrun\`\n";
	print Queue "GMXRC\n";

	# The && in the end of the normal gromacs-command means that it will be executed ONLY if the the previous command has 
	# finished running **successfully**. main.pl tests to see when {JbName}.txt file has been created, which indicates the job ended.
	# This way when the job moves nodes/suspends the txt file is not created. I hope!
	# P.S. on the cluster we use nice 0 by default.
	# P.P.S. on the light queue simulations are automatically set to "resume" regardless of param.arq. This is because the job may switch machines and therefore be killed and resumed many times
	print Queue "cr_run mpiexec -machinefile hosts.\$JOB_ID  -np \$NSLOTS  mdrun -v -nice 0 -cpt 1 -cpo ${JbName}.cpt -v -s ${JbName} -deffnm ${JbName} -np \$NSLOTS -cpi ${JbName}.cpt -append > ${JbName}.std && echo \"Job ${JbName} has been finished. You may erase this file.\" \>${JbName}.txt\n\n";
	print Queue "smpd -shutdown\n";
	print Queue "exit 0\n";
	close Queue;

}

# Reads parameter file
sub Read_Param_File {
	# 	Read_Param_File (type filter text $filename)
	my $file = $_[0];
	open( PARAM, "<$file" ) 	  or die( "Parameter file $file does not exist! Cowardly refusing to continue NewARQ. \n"  );
	my %Ret_Parameters;
	while ( defined( my $line = <PARAM> ) ) {
		chomp $line;
		RemoveWhitespace($line);
		my @Remove_Comments = split( /#/, $line );
		my $linecontent = $Remove_Comments[0];
		if ( $linecontent ne "" ) {
			$linecontent =~ s/\s//g;    # Globally replacing spaces
			my @Temp  = split( /=/, $linecontent );
			my $Field = $Temp[0];
			my $Value = $Temp[1];
			if ( ( $Field eq "" ) || ( $Value eq "" ) ) {
				#print "$Field\t$Value\n$line\n";
				die("Undefined field or value in parameter file: $Field = $Value \n\n" 	);
			}
			else {                      # Create hash for parameter values
				$Ret_Parameters{ lc($Field) } = $Value;
			}
		}

	}

	close(PARAM);
	return (%Ret_Parameters);
}

# ----------------------------- START NewARQ main.pl -----------------------------------
# Getting parameter file values from param.arq
my %PRMs;    # Parameters hash.
%PRMs = ( Read_Param_File("param.arq") );

# Uncomment these lines to apply limitation on counter.
#my $runlimit=5;
#if ($PRMs{counter} > $runlimit) { die ("Error: counter > $runlimit ($PRMs{counter}). Maximum number of iterations allowed is $runlimit Check your param.arq file.\n"); }

while ( $PRMs{counter} > 0) {	
	my $mainlogfile="main$PRMs{runnumber}.log";
	open (MAIN_LOG, ">$mainlogfile") or die ("Cannot create main log file. Perhaps you don't have permissions here?\n");

	my $CuRName="$PRMs{genname}$PRMs{runnumber}";	# **Current** Run Name. It is GenName+RunNumber. This is the simulation the is going to run soon.
	print MAIN_LOG "This is the log file for $CuRName. Problems in execution are listed below, or in cluster/gromacs related log files.\n";
	print MAIN_LOG "Use these files for debugging purposes.\n";
	print MAIN_LOG "Current PID: $$.\n";
	print MAIN_LOG "Kill this PID if for some reason the script did not finish running.\n";

	# Running OS command (Linux), using $mainlogfile as logfile
	# First, moving all current files to include their RunNumber. For example Test.tpr --> Test1.tpr
	GC_Run("mv param.arq param$PRMs{runnumber}.arq", *MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("cp $PRMs{genname}.tpr $CuRName.tpr", *MAIN_LOG) ne "-1" or (Email(-1, %PRMs));

	my $Sim_Time;	# This value is used to check that the simulation ran successfully the entire specified time. time in [ns]
	Write_New_Param("param.arq", %PRMs);	# Writing new param.arq
	if ( lc($PRMs{"resume"}) eq "yes") {	
		$PRMs{"resume"} = "-append -cpi $CuRName.cpt"; # $PRMs{"resume"} is now inserted to the command line. 
	} else {
		$PRMs{"resume"}=""; # $PRMs{"resume"} is inserted to the command line, but is empty so no resume.
	}
		
	my $TotalSimTime=($PRMs{"extend"})/1000+$PRMs{"starttime"}; 	# Total simulation time [ns] is Start Time + extend time. Remember that extend is [ps] so we convert by /1000. 

	# Control: Used to run proper commands for either desktop/cluster simulations in either gromacs 4.0.x/4.5.x. 
	# If you want to apply changes to the script, this is probably the place you need. 
	# --------- Control I Start ---------------
	my $runtype=lc($PRMs{"runtype"});	# Applies lowercase to runtype field.

	Email(1, %PRMs); # Emailing user

	# Gromacs 4.0.x and Gromacs 4.5.x have the same execution command style. Hoever, user may want to take advatage of additional option available in 4.5.x. 
	if ($runtype eq "desktop") {		# DESKTOP MODULE
		printf "RUNNING DESKTOP MODULE, JOB: $CuRName, Counter=$PRMs{counter}\n";
		if ($PRMs{"gromacsver"} == 4) {
			print "\tRUNNING GROMACS 4 DESKTOP\n";
			GC_Run("mpirun -np $PRMs{ncpus} mdrun -nice $PRMs{nice} -v -s $CuRName -deffnm $CuRName $PRMs{resume} &> $CuRName.std", *MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
		} elsif ($PRMs{"gromacsver"} == 45) {
			print "\tRUNNING GROMACS 4.5 DESKTOP\n";
			GC_Run("mpirun -np $PRMs{ncpus} mdrun -nice $PRMs{nice} -v -s $CuRName -deffnm $CuRName $PRMs{resume} &> $CuRName.std", *MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
		} else {
			print MAIN_LOG "Something is improper with parameter file. gromacsver may be either 4 or 45\nAborting\n";
			die("Unexpected Error. Please check main log file\n");
		}
	} elsif ( ($runtype eq "hemi") || ($runtype eq "light") ) {	# CLUSTER MODULE, this is the list of exists queues, if ever you want to add more. Anything added here will arrive to qsub -l $runtype 
		printf "RUNNING CLUSTER MODULE, JOB: $CuRName, Counter=$PRMs{counter} \n";
		# Remember - cluster environment has to be set to the correct gromacs version!! (Both headnode and nodes) 

		# Creating Queue file for CLUSTER module. The Write_Queue() subroutine often needs updates for specific cluster configurations.
		# Writing normal or light sge file, and sending job to cluster.
		my $RetStat="";
		if ($runtype eq "hemi") { 
			$RetStat=Write_Queue(%PRMs);	# regular cluster sge file
		} elsif ($runtype eq "light") {
			$RetStat=Write_Queue_Light(%PRMs);	# light cluster sge file
		} 
		
		if ($RetStat =~ m/ERROR/) {
			print MAIN_LOG "Something is improper with parameter file. gromacsver may be either 3 or 4\nAborting\n";
			die("Unexpected Error. Please check main log file\n");
		}

		# Cluster-specific code
		# Saving job-id from qsub's output.
		# job id given by qstat should look like this:
		# "Your job 1428972 ("Grom4Test1") has been submitted". If this changes for some reason, just update the regexp.
		my $qsubcmd="qsub -l $runtype ${CuRName}.sge";
		my $RetStat=GC_Run("$qsubcmd", *MAIN_LOG);
		my $jobid="";
		if ($RetStat eq "-1") {	# error
			print MAIN_LOG "* ERROR: $qsubcmd . Perhaps something is wrong with the cluster.\n $RetStat\n ";
			Email(-1, %PRMs);			
		} elsif ($RetStat =~ m/job\s+(\d+)/) {	# success, and save jobid
			$jobid=$1;
		} 
		# Waiting for gromacs to finish. Checking if script was finished every 1 minute (using sleep() )
		# Cluster specific code (relaying on qstat command). 
		my $CheckFinish=0;
		while ($CheckFinish eq "0") { 	# When qstat fails GC_Run returns -1. This happens when the job is finished, or when qstat actually fails due to cluster issues. 
			sleep(60);
			$CheckFinish=QSTAT_Run("qstat -j $jobid"); # The same as GC_Run, only QSTAT_Run does not write to logfile (uninformative), but returns output.
			if ($CheckFinish ne "0" ) {
				print MAIN_LOG "* NOTE: qstat reports that job $jobid is no longer in queue. This does not nessecerily means it was successful.\n";
			}

		}

		# when mdrun is done the sge file creates a temporary txt file. This marks that mdrun exited *successfully*.
		if (-e "${CuRName}.txt") {	 
			GC_Run("rm ${CuRName}.txt",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs)); # Removing the temporary file that marks that the job was finished.
		} else {
			print MAIN_LOG "* WARNING: Could not find ${CuRName}.txt. This probably means that the job was somehow halted. Check output carefully.\n";			
		}
		
	} else {
		print MAIN_LOG "Something is improper with parameter file. runtype may be desktop or cluster\nAborting\n";
		die ("Unexpected Error. Please check main log file\n");
	}
	# --------- Control I End ---------------
	
	# Checking if trr file is both corrent and full (time-wise).
	my $TotalSimTime_ps=$TotalSimTime*1000;
	GC_Run("gmxcheck -f $CuRName.trr", *MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	my $RetStat=GC_Run("trjconv -f $CuRName.trr -dump $TotalSimTime_ps -o ${CuRName}_lastframe".$TotalSimTime."ns.trr", *MAIN_LOG);
	if ($RetStat =~ m/WARNING no output/) {
		print MAIN_LOG "* ERROR: Though trjconv was successful I detect the trajectory is NOT complete (ends before ".($PRMs{extend})."ps has passed). This usually suggest something is wrong with your settings, or unexpected shutdown.\n ";
		Email(-1, %PRMs);
	}

	# --------- Control II Start ---------------
	# This is the grompp function. Separated for gromacs 4 and 4.5 even though they essentially have the same grompp.
	my %NxPRMs = ( Read_Param_File("param.arq") ); 			# Reading the new param.arq for next run parameters (for adjustable parameters, for example you user wants different extend number) 
	
	if ($PRMs{"gromacsver"} == 4) {
		print "EXECUTING GROMACS 4 grompp\n";
		GC_Run("tpbconv -s ${CuRName}.tpr -f ${CuRName}.trr -e ${CuRName}.edr -cont -time $TotalSimTime_ps -extend $NxPRMs{extend} -o $PRMs{genname}", *MAIN_LOG)  ne "-1" or (Email(-1, %PRMs));
		
	} elsif ($PRMs{"gromacsver"} == 45) {
		print "EXECUTING GROMACS 4.5 grompp\n";
		GC_Run("tpbconv -s ${CuRName}.tpr -f ${CuRName}.trr -e ${CuRName}.edr -cont -time $TotalSimTime_ps -extend $NxPRMs{extend} -o $PRMs{genname}", *MAIN_LOG)  ne "-1" or (Email(-1, %PRMs));
	}
	# On the next iteration $PRMs{genname} will be renamed to include RunNumber
	
	# --------- Control II End ---------------

	# Moving files
	# All files created in the simulation will be moved to a directory by the name: StartTime-(StartTime+Sim_Time)
	# For example: Directory for 2ns TEST simulation from StartTime 3ns will have the name 3000-5000ps
	my $DirName=($PRMs{"starttime"}*1000)."-".($TotalSimTime*1000)."ps";
	GC_Run("mkdir $DirName", *MAIN_LOG)  ne "-1" or (Email(-1, %PRMs)); 
	GC_Run("mv $CuRName.log ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv $CuRName.tpr ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs)); 
	GC_Run("mv $CuRName.gro ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv $CuRName.edr ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv $CuRName.trr ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv $CuRName*.cpt ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv $CuRName*.std ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv ${CuRName}_lastframe".$TotalSimTime."ns.trr ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	GC_Run("mv param".$PRMs{"runnumber"}.".arq ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));
	Email(2, %PRMs);	# Sending email to user. It uses main*.log as body text, so we move it only after the job is done.
	GC_Run("mv main".$PRMs{"runnumber"}.".log ./$DirName",*MAIN_LOG) ne "-1" or (Email(-1, %PRMs));

	# ------------------------------ END NewARQ -----------------------------------
	%PRMs = ( Read_Param_File("param.arq") ); 	# Updating parameter data in case it was changed between iterations
	my $Quote=GetQuote();	# Getting quote from internet (if possible)
	print MAIN_LOG "\nThis NewARQ cycle has been finished.\n-----------------------------------------------------\n$Quote\n\n";
	print "-----------------------------------------------------\n$Quote\n\n";
	close (MAIN_LOG);

}

if ($PRMs{"counter"} < 1) {
	die ("NewARQ script has finished running. Now go away.\n");
}

die ("NewARQ finished running. View log files for information.\n")



