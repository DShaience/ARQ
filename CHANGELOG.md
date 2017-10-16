CHANGELOG
-------------------
Version	2.02	22.01.2012
* Bugfix: fixed a bug where the 'extend' parameter was not adjustable. Changing extend would cause error
  Users can now set extend=t1 in several iterations, and then change it so that the next iteration would run t2 ps.    

Version 	2.01	19.01.2012
* NOTE: !!!Removed!!! support for the obsolete GROMACS 3.3.3
* mpich2 support has been restored.
* normal queue and light queue are now supported separately. Each has its one sge-writing function:
  Write_Queue() and Write_Queue_Light()  
* Added support for GROMACS 4.5.x. Note that now user can choose between GROAMCS 4.0.x and 4.5.x by setting 
  gromacsver=4 or gromacsver=45 (respectively) in the param file
* Queue update: added stricter control to job execution on the cluster.
  Previously, if for some reason a job got deleted before it finished running, then main.pl would continue running
  in memory indefinitely, waiting for a job to finish, and it never would. This created numerous problems (for example, you can't erase the directory if main.pl is still running on it) 
  To avoid that, main.pl now uses qstat to test if the job is still in queue. 
  When the job is no longer reported in qstat, we test for successful ending of the simulation.  
  Any failure in those tests invokes email to user, and main.pl dies. This eliminates the problem. 
* GC_Run: corrected an error, where on success GC_Run would not return command output. 
 	This caused trjconv not to recognize when the trr was incomplete (meaning, the simulation was aborted in the middle). 
* The cluster does not allow for job names to start with a number. We previously solved this annoyance by adding
  "A_" prefix to all jobs. Instead, we now check to make sure job name starts with a letter. If not, "A_" is 
  automatically added.
* Added counter to email. 
* Removed counter limitation of <= 5. Also, counter may be updated in param.arq even during main.pl run. 
* mainXX.log file saves PID information, just in case.
* IMPORTANT: no need for topology files. Extension of simulation is now down by using tpbconv.
  param.arq file was updated, instead of "mdp=file.mdp" there is now "extend=time". time is the the in [ps] to run simulation.
  Now only tpr file is needed, instead of all the other topology files.
* Side effect of tbpconv: simulation times are now consecutive. No need to use -settime when concatenating with trjcat.
  Also, the order doesn't matter. "trjcat -f file1 file4 file2 file3 -o complete" and trjcat will concatenate in the correct order, 1-4 
* cpt file are now moved to the same directory with the rest of the simulation files.
* IMPORTANT: "resume" is set to "yes" by default in param.arq files.
  If you don't want to resume, erase/move the files.
* Added several new records to main*.log. 
* Added Random Quotes!! :D :D

  
Version 	1.11_orte	16.08.2011
* light doesn't work now. Reverting back to orte module. 
* This version is unsupported.

Version 	1.11	2.08.2011
* Emailing is now written as a function. Current options: -1 (error), 0 (success, but don't email), 1 (simulation starting), 2 (simulation ending)
* Emails upon error (appends error description from main*.log file)
* All GC_Run() statements are coupled with emailing 
  GC_Run(... whatever) == 0 or (Email(emailcode))

Version 	1.10	31.07.2011
* Updated light queue options. Runs smoothly with migration. "runtype=light" for light queue.
* resume=yes now works correctly anywhere.

Version 	1.09	28.07.2011
* Added email notification also when job starts (user requests).
* FIXED: Fixed a bug where main.pl would continue running after job failed/was deliberately terminated. 
* resume=yes option works ONLY on Desktop currently.

Version 	1.08	26.05.2011
* IMPORTANT: "cluster" option was substituted by "hemi". Now you must write "runtype=hemi" for the cluster option.
* Updated light queue to use Migration (between nodes), BLCR, Checkpoint etc. 
  Now jobs can "jump" between nodes on the light queue (aka migration).

Version 	1.07	28.01.2011
* IMPORTANT: "cluster" option was substituted by "hemi". Now you must write "runtype=hemi" for the cluster option.
#	This change makes it easier to implement more queue-types (such as light).
* Added runtype=light. This is the same as the "hemi" option but running on the 'light' queue.
* Added to param.arq a new option "resume=yes/no". If a simulation stopped this option will use the 
#	"-append -cpi JobName.cpt" to resume the simulation. 
#	Afterwards, the resume option will be automatically reset back to "no".
* Minor change: all mdrun use now the "-deffnm" for default naming. This is transparent and does not affect function.  

Version 	1.06 	27.01.2011
BUG-FIXES
* orte enabled (due to recurring problems with mpich it was disabled for the time being).
* IMPORTANT NOTE: Ubuntu does not install the 'mail' command by default. 
                  You must install "bsd-mailx" package for mail option to work, or set it to 'none'.
                  Using mail option from non-university computers may not work.
* New Feature - Supports "Desktop" option in param.arq. This enables to run simulations on desktop computers (tested for CenOS and Unubtu).
* Tracking Jobs - On desktop computers the estimation of job-ending is in nohup.out file. On lecs it is the usual.
* Fixed a problem where the script would suddenly abort. It was caused due to a wrong placement of "&". The piping to .std file was ">&" instead of "&>". 
  This typically occurred on Ubuntu-running computers.

Version 	1.051 	02.01.2011
mpich2 enabled (with BLCR)
Cluster Mode Enabled

BUG-FIXES	1.05	02.01.2011
* Updated Write_Queue() to work with new #####Version of mpich2 (with BLCR)

BUG-FIXES	1.04	09.12.2010
* Updated Write_Queue() to work with new #####Version of mpich2

BUG-FIXES	1.03	23.11.2010
* Cluster Jobs that were finished did not free-up the node. Added smpd "-shutdown" to .sge file to force shutdown of smpd 
  and freeing the node. 

BUG-FIXES	1.02	27.5.2010
* Lecs-cluster prohibits jobname from starting with numbers. To avoid this NewARQ now appens "ARQ_" as prefix to all jobnames.
* NewARQ quits jobs before they were truly finished: Lecs' qstat command was giving sometimes false information, as if the 
  Job was finished. The bug was fixed by adding to Write_Queue() sub the ability to write temporary file to signal the job
  was indeed finished. Now NewARQ checks for the existance of the temporary file, instead of relying on server-sided qstat. 
