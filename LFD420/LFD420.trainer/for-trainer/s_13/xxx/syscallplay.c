#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>  // needed for several syscalls
#include <sys/wait.h>   // needed for waitpid() syscall
#include <signal.h>     // needed for kill() syscall
#include <unistd.h>     // main header file for the kernel interface

// syscallplay.c -- set up a pipe so the parent can read from the child,
//  create a child and have him exec a file, sending the stdout of that
//  program to the parent through the pipe.
//
//  The parent will read the pipe until EOF, then wait for the child
//  to "reap" his exit status.

char *ourname;

int main(int ac, char **av)
{
        int pipefds[2];// file descriptors for the pipe -- see man 2 pipe
        int status;    // child's exit status --- see man 2 waitpid
        pid_t kidpid;
        int   i;
        FILE  *fp;     // turn pipe descriptor into a STREAM
        char  buf[1024];

        if ((ourname = strrchr(*av, '/')) == NULL)
                ourname = *av;  // no '/' in first arg
        else
                ++ourname;   // point just past the rightmost '/'

        // create the pipe before the child, so that both processes
        //  can use it.
        if (pipe(pipefds) != 0) {
                fprintf(stderr, "%s:  pipe syscall failed:  %s\n",
                        ourname, strerror(errno));
                exit(1);
        }
        // try to create the child process.  Quit if we fail 3 times
        for (i = 0; i < 3; i++) {
                kidpid = fork();
                if( kidpid >= 0)
                        break;   // success!
                // fork() failed.  See why
                fprintf(stderr, "%s:  fork failed:  %s\n", ourname,
                        strerror(errno));
        }
        if (kidpid < 0) {
                fprintf(stderr, "%s:  fork failed too many times.  Quitting\n",
                        ourname);
                exit(1);
        }
        // now split the code:  one part runs in the parent, the other in
        //   the child
        if (kidpid == 0) {
                // running in the child process
                char *argvec[2];
                extern char **environ;  // environment variables

                // IF there were any arguments on the command line,
                // THEN run the command "ps axl --forest" to show ourselves
                if (ac > 1) {
                        printf("%s CHILD:  running \"ps axl --forest\"\n",
                               ourname);
                        fflush(stdout);
                        system("ps axl --forest");
                        printf("%s CHILD:  press <ENTER> to continue --> ",
                               ourname);
                        (void) fgets(buf, sizeof(buf), stdin);
                }
                argvec[0] = "/bin/ls";
                argvec[1] = NULL;   // end-of vector sentinel
        
                // close off the "read end" of the pipe.
                close(pipefds[0]);
                // copy pipefds[1] to the stdout position
                close(1);
                dup(pipefds[1]);  // also look at "man 2 dup" to see dup2()

                execve(argvec[0], argvec, environ);
                // this returns ONLY on error
                fprintf(stderr, "%s CHILD:  execve failed:  %s\n",
                        ourname, strerror(errno));
                exit(1);
        }
        // running in the parent
        //  close "write end" of the pipe
        close(pipefds[1]);
        // for ease of use, convert pipe descriptor into a STREAM
        if ((fp = fdopen(pipefds[0], "r")) == NULL) {
                fprintf(stderr, "%s:  fdopen failed:  %s\n", ourname,
                        strerror(errno));
                kill(kidpid, SIGKILL);
        } else {
                // read from the pipe until EOF
                while (fgets(buf, sizeof(buf), fp)) {
                        printf("child sends:  %s", buf);
                }
        }
        //  child is done working, or we have killed him, or he has failed/quit
        (void) waitpid(kidpid, &status, 0);
        // see why he quit
        if (WIFEXITED(status)) {
                if (WEXITSTATUS(status) == 0) {
                        printf("%s:  child exited normally\n", ourname);
                        return 0;   // overall program succeeded
                } else {
                        printf("%s:  child exited ABNORMALLY:  exit code %d\n",
                               ourname, WEXITSTATUS(status));
                }
        } else {
                // WIFSIGNALED is only other possibility
                printf("%s:  child killed by signal %d\n", ourname,
                       WTERMSIG(status));
        }
        return 1;  // overall program failure
}

        
        
