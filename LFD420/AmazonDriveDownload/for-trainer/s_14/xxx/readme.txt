Note, that you can as a normal user not change ulimit -c to anything after you made it 0;)

as user:

lab1_limit
Printing out all limits for pid=5811:
     RLIMIT_CPU= 0: cur=18446744073709551615,     max=18446744073709551615
    RLMIT_FSIZE= 1: cur=18446744073709551615,     max=18446744073709551615
     RLMIT_DATA= 2: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_STACK= 3: cur=             8388608,     max=18446744073709551615
    RLIMIT_CORE= 4: cur=                   0,     max=                   0
     RLIMIT_RSS= 5: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_NPROC= 6: cur=18446744073709551615,     max=18446744073709551615
  RLIMIT_NOFILE= 7: cur=                1024,     max=                4096
 RLIMIT_MEMLOCK= 8: cur=               65536,     max=               65536
      RLIMIT_AS= 9: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_LOCKS=10: cur=18446744073709551615,     max=18446744073709551615

Before Modification, this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=                   0
I forked off a child with pid = 0

After  Modification, this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=                   0


In child pid= 5812 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=                   0

In child pid= 5814 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=                   0
In child pid= 5813 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=                   0
Parent got return on pid=5812n
Parent got return on pid=5814n
Parent got return on pid=5813n
Parent got return on pid=-1n
 **************************************************** 
For RUSAGE_SELF
ru_utime.tv_sec, ru_utime.tv_usec =    0     0 (user time used)
ru_stime.tv_sec, ru_stime.tv_usec =    0  2999 (system time used)
ru_maxrss =  7708 (max resident set size)
ru_ixrss =      0 (integral shared memory size)
ru_idrss =      0 (integral unshared data size)
ru_isrss =      0 (integral unshared stack size)
ru_minflt =   190 (page reclaims)
ru_majflt =     0 (page faults)
ru_nswap =      0 (swaps)
ru_inblock =    0 (block input operations)
ru_oublock =    0 (block output operations)
ru_msgsnd =     0 (messages sent)
ru_msgrcv =     0 (messages received)
ru_nsignals=    0 (signals received)
ru_nvcsw=       3 (voluntary context switches)
ru_nivcsw=     38 (involuntary context switches)

For RUSAGE_CHILDREN
ru_utime.tv_sec, ru_utime.tv_usec =    0     0 (user time used)
ru_stime.tv_sec, ru_stime.tv_usec =    0     0 (system time used)
ru_maxrss =   256 (max resident set size)
ru_ixrss =      0 (integral shared memory size)
ru_idrss =      0 (integral unshared data size)
ru_isrss =      0 (integral unshared stack size)
ru_minflt =   162 (page reclaims)
ru_majflt =     0 (page faults)
ru_nswap =      0 (swaps)
ru_inblock =    0 (block input operations)
ru_oublock =    0 (block output operations)
ru_msgsnd =     0 (messages sent)
ru_msgrcv =     0 (messages received)
ru_nsignals=    0 (signals received)
ru_nvcsw=      11 (voluntary context switches)
ru_nivcsw=     16 (involuntary context switches)

----------------

as root:

lab1_limit
Printing out all limits for pid=5879:
     RLIMIT_CPU= 0: cur=18446744073709551615,     max=18446744073709551615
    RLMIT_FSIZE= 1: cur=18446744073709551615,     max=18446744073709551615
     RLMIT_DATA= 2: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_STACK= 3: cur=             8388608,     max=18446744073709551615
    RLIMIT_CORE= 4: cur=                   0,     max=18446744073709551615
     RLIMIT_RSS= 5: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_NPROC= 6: cur=18446744073709551615,     max=18446744073709551615
  RLIMIT_NOFILE= 7: cur=                1024,     max=                4096
 RLIMIT_MEMLOCK= 8: cur=               65536,     max=               65536
      RLIMIT_AS= 9: cur=18446744073709551615,     max=18446744073709551615
   RLIMIT_LOCKS=10: cur=18446744073709551615,     max=18446744073709551615

Before Modification, this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=                   0,     max=18446744073709551615
I forked off a child with pid = 0

After  Modification, this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=             8388608,     max=18446744073709551615

In child pid= 5880 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=             8388608,     max=18446744073709551615

In child pid= 5882 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=             8388608,     max=18446744073709551615

In child pid= 5881 this is RLIMIT_CORE:
    RLIMIT_CORE= 4: cur=             8388608,     max=18446744073709551615
Parent got return on pid=5880n
Parent got return on pid=5882n
Parent got return on pid=5881n
Parent got return on pid=-1n
 **************************************************** 
For RUSAGE_SELF
ru_utime.tv_sec, ru_utime.tv_usec =    0     0 (user time used)
ru_stime.tv_sec, ru_stime.tv_usec =    0   999 (system time used)
ru_maxrss =  3644 (max resident set size)
ru_ixrss =      0 (integral shared memory size)
ru_idrss =      0 (integral unshared data size)
ru_isrss =      0 (integral unshared stack size)
ru_minflt =   190 (page reclaims)
ru_majflt =     0 (page faults)
ru_nswap =      0 (swaps)
ru_inblock =    0 (block input operations)
ru_oublock =    0 (block output operations)
ru_msgsnd =     0 (messages sent)
ru_msgrcv =     0 (messages received)
ru_nsignals=    0 (signals received)
ru_nvcsw=       2 (voluntary context switches)
ru_nivcsw=     38 (involuntary context switches)

For RUSAGE_CHILDREN
ru_utime.tv_sec, ru_utime.tv_usec =    0     0 (user time used)
ru_stime.tv_sec, ru_stime.tv_usec =    0     0 (system time used)
ru_maxrss =   256 (max resident set size)
ru_ixrss =      0 (integral shared memory size)
ru_idrss =      0 (integral unshared data size)
ru_isrss =      0 (integral unshared stack size)
ru_minflt =   162 (page reclaims)
ru_majflt =     0 (page faults)
ru_nswap =      0 (swaps)
ru_inblock =    0 (block input operations)
ru_oublock =    0 (block output operations)
ru_msgsnd =     0 (messages sent)
ru_msgrcv =     0 (messages received)
ru_nsignals=    0 (signals received)
ru_nvcsw=       6 (voluntary context switches)
ru_nivcsw=     20 (involuntary context switches)

