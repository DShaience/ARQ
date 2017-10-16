ARQ (NewARQ) - Automatic Re-Qsub (The new version)
---------------------------------------------------------------------------
Auto Re-Qsub for GROMACS - an automation utility script to automate GROMACS simulation submissions, processes, and healthchecks
console> nohup perl mainND.pl &
Loads param.arq automatically, which should always be in the same working directory as mainND.pl
Resubmitting GROMACS jobs on a desktop (or server) machine.

This script was tested using GROMACS 4.x.x under Linux, and should work great with them. For other versions, it should work, but may require some slight manual adjustments for the grompp and mdrun commands, that have significanly changed over the years.

Ajusting these lines will make it also easy to use NewARQ if you intend on using any GPU-enabled version of gromacs. Previous versions supported running on computer clusters, but with the emergence of cloud computing, this part of the code has become obsolete. runtype should ALWAYS be set to desktop (runtype=Desktop)

FILE LIST
---------------------------------------------------------------------------
* mainND.pl
* param.arq
MANDATORY GROMACS FILES (List of gromacs-files required by NewARQ to operate):
* myrun.tpr
Since version 2.x no other topology files are needed. Everything is stored in the .tpr file, so it is
used to extend the simulation further, under the same parameters and conditions
