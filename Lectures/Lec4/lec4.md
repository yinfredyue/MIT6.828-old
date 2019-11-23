## Lecture 4

### Homework Solution
* exec  
    - why two execv() arguments? 

        The first argument is the executable file name, and the second is the arguments.
    - what happens to the arguments?  

        Passed to the executable file as parameters.

    - what happens when exec'd process finishes?  

        It exits. 

    - can execv() return?  

        Return `-1` only if error occurs.  
    - how is the shell able to continue after the command finishes?  

        Call `exec` in a child process and wait for the child process to terminate in the parent process.  

* redirect
    - how does exec'd process learn about redirects? [kernel fd tables]

        They do not know about it. They just read from/write to the file descriptor. You can achieve redirection by manipulating the file descriptors.  

    - does the redirect (or error exit) affect the main shell?  

        No.
* pipe  
    **Properties of pipe from COMP3230**  
    1. If a process attemps to write to a full pipe, write blocks until sufficient data has been read from the pipe.
    2. If a process attempts to read from an empty pipe, read blocks until data is available.
    3. If all file descriptors referring to the write end of a pipe are closed, reading the pipe returns `EOF`.  

    **Questions**  
    Consider `ls | wc -l`:   
    - what if `ls` produces output faster than `wc` consumes it? what if `ls` is slower than `wc`?

        If `ls` is faster, than `wc` has something to consume when being executed. If `ls` is slower, `wc` would be blocked, waiting for the data. This is the behavior of the pipe.  

    - how does each command decide when to exit?

        When it sees EOF from the input file descriptor.

    - what if reader didn't close the write end? [try it]
        
        Then the reader would be blocked, waiting for new data from the pipe. Because it has not seen EOF.

    - what if writer didn't close the read end?

        The pipe still works.

    - how does the kernel know when to free the pipe buffer?

        When the refernce count of the both sides becomes zero.

    * how does the shell know a pipeline is finished? E.g. `ls | sort | tail -1` 

        When all child processes terminate. 


    * what's the tree of processes?
    `sh` parses as:  
        ```
        ls | (sort | tail -1)
            sh
            sh1
        ls      sh2
            sort   tail
        ```

    * does the shell need to fork so many times?  

        Not necessarily. For example, `sh2` itself could execute `tail` or `sort`. But this is more complicated in terms of implementation.  
        - what if `sh` didn't `fork` for `pcmd->left`? [try it]
            i.e. called `runcmd()` without forking?
            ``` C
            // Without fork() for runcmd(pcmd->left)
            case '|':  // With single fork
                pcmd = (struct pipecmd *)cmd;

                int p[2];
                pipe(p);

                // Run right
                if (fork1() == 0) {
                    close(0);
                    dup(p[0]);  // dup read end to fd 0

                    close(p[0]);  // close pipe
                    close(p[1]);
                    runcmd(pcmd->right);
                }

                // Run left
                close(1);
                dup(p[1]);  // dup write end to fd 1

                close(p[0]);  // close pipe
                close(p[1]);
                runcmd(pcmd->left);

                wait(NULL);  // Useless
                break;
            ```

            The behavior is changed. When `runcmd(pcmd->left)` is directly executed in the parent process, it would not return from the call but directly `_exit`. Thus, `wait(NULL)` is not executed. Thus, the main process could be resumed earlier than the right command terminates:
            ```
            6.828$ ls | cat
            6.828$ Makefile
            sh
            sh.c
            t.sh

            6.828$
            ```

        - what if `sh` didn't `fork` for `pcmd->right`? [try it]  
            would user-visible behavior change?
            `sleep 10 | echo hi`

            ```C
            case '|':  // With single fork
                pcmd = (struct pipecmd *)cmd;

                int p[2];
                pipe(p);

                // Run left
                if (fork1() == 0) {
                    close(1);
                    dup(p[1]);  // dup write end to fd 1

                    close(p[0]);  // close pipe
                    close(p[1]);
                    runcmd(pcmd->left);
                }

                wait(NULL);

                // Run right
                close(0);
                dup(p[0]);  // dup read end to fd 0

                close(p[0]);  // close pipe
                close(p[1]);

                runcmd(pcmd->right);
            ```
            wait for left command to terminate would work.

* why `wait()` for pipe processes only after both are started?    
    what if `sh` `wait()`ed for `pcmd->left` before 2nd `fork`? [try it]  
    `ls | wc -l`  
    `cat < big | wc -l`  

    The behavior is correct. 

* The point: the system calls can be combined in many ways to obtain different behaviors.