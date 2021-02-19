#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#if MINGW
#include <windows.h>
#include <process.h>
#include <inttypes.h>
#else
#include <errno.h>
#include <unistd.h>
#include <time.h>
#include <pthread.h>
#endif

#define handle_error_en(en, msg) \
    do { errno = en; perror(msg); exit(EXIT_FAILURE); } while (0)

enum { NUM_THREADS = 3 };

static int g_x = 0;

#if MINGW
HANDLE ghMutex;

unsigned __stdcall thread_func(void * arg)
{
    int y;
    DWORD dwWaitResult = WaitForSingleObject(ghMutex, INFINITE);
    switch (dwWaitResult) {
        case WAIT_OBJECT_0: 
            printf("Thread %lu incrementing global\n", GetCurrentThreadId());
            break; 
        case WAIT_FAILED: 
            fprintf(stderr, "ERROR: WaitForSingleObject(): WAIT_FAILED\n");
            break;
        case WAIT_ABANDONED: 
            fprintf(stderr, "ERROR: WaitForSingleObject(): WAIT_ABANDONED\n");
            break; 
    }
    y = g_x;
    Sleep(1000);
    y++;
    g_x = y;
    printf("g_x: %d\n", g_x);
    printf("ARG: %p\n", arg);
    if (!ReleaseMutex(ghMutex)) { 
        fprintf(stderr, "ERROR: cannot ReleaseMutex\n");
    } 
    return 0;
}
#else

pthread_mutex_t mymutex = PTHREAD_MUTEX_INITIALIZER; 

void * thread_routine(void * arg)
{
    static int tid = 0;
    int arg_int = *((int *) arg);
    int * x = malloc(sizeof(*x));
    struct timespec ts = {.tv_sec = 0, .tv_nsec = 500000000L};
    int y;

    pthread_mutex_lock(&mymutex);

    y = g_x;

    printf("%d: %p\n", arg_int, arg);
    fflush(stdout);
    if (nanosleep(&ts, NULL) != 0) {
        perror("nanosleep()");
        exit(EXIT_FAILURE);
    }
    y++;
    g_x = y;

    printf("g_x: %d\n", g_x);

    *x = tid++;

    pthread_mutex_unlock(&mymutex);

    return x;
}
#endif

int main()
{
    size_t i;
#if MINGW
    void * security = NULL;
    //unsigned stack_size = 0x100000;
    unsigned stack_size = 0; // 0: use default
    void *arglist = NULL;
    unsigned initflag = 0;
    unsigned *thrdaddr = NULL;
    HANDLE threads[NUM_THREADS];
    /* create mutex */
    ghMutex = CreateMutex(NULL, FALSE, NULL);
    if (ghMutex == NULL) {
        printf("CreateMutex error: %lu\n", GetLastError());
        return 1;
    }
    /* spawn threads */
    for (i=0; i < NUM_THREADS; i++) {
        threads[i] = (HANDLE)_beginthreadex(security, stack_size, thread_func, arglist, initflag, thrdaddr);
        //printf("Thread: %" PRIxPTR "\n", threads[i]);
        printf("Thread: %p\n", threads[i]);
    }
    /* join threads */
    for (i=0; i < NUM_THREADS; i++) {
        DWORD dwWaitResult = WaitForSingleObject(threads[i], INFINITE);

        switch (dwWaitResult) {
            case WAIT_OBJECT_0:
                printf("Thread joined\n");
                break;
            default:
                break;
        }

        CloseHandle(threads[i]);
    }
    CloseHandle(ghMutex);
#else
    pthread_t threads[NUM_THREADS];
    int * retval;
    int thread_args[NUM_THREADS];
    /*const pthread_attr_t attr;*/
    for (i=0; i < NUM_THREADS; i++) {
        thread_args[i] = (int) i;
        int err = pthread_create(threads+i, NULL, thread_routine, thread_args+i);
        if (err != 0)
            handle_error_en(err, "pthread_create");
    }

    for (i=0; i < NUM_THREADS; i++) {
        printf("waiting for thread #%zu to join...\n", i);
        fflush(stdout);
        pthread_join(threads[i], (void **)(&retval));
        printf("thread rejoined: %d\n", *retval);
        fflush(stdout);
        free(retval);
    }
#endif

    return 0;
}
