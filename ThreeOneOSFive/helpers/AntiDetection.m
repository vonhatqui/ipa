//
//  AntiDetection.m
//  3105 / CheatStore VN
//
//  Enhanced Process Security & Anti-Analysis
//  1. Overrides fork() to defeat jailbreak/sandbox detection heuristics
//  2. Enforces ptrace(PT_DENY_ATTACH) to block LLDB, IDA & Frida debuggers
//

#import <unistd.h>
#import <errno.h>
#import <dlfcn.h>
#import <sys/types.h>

#ifndef PT_DENY_ATTACH
#define PT_DENY_ATTACH 31
#endif

typedef int (*ptrace_ptr_t)(int _request, pid_t _pid, caddr_t _addr, int _data);

// Chặn debugger (LLDB / IDA / Frida) đính kèm vào tiến trình
__attribute__((constructor))
static void apply_runtime_security_protections(void) {
    void *handle = dlopen(NULL, RTLD_GLOBAL | RTLD_NOW);
    if (handle) {
        ptrace_ptr_t ptrace_func = (ptrace_ptr_t)dlsym(handle, "ptrace");
        if (ptrace_func) {
            ptrace_func(PT_DENY_ATTACH, 0, 0, 0);
        }
    }
}

// Any fork() call from this process fails immediately.
// This defeats jailbreak-detection tests that check whether fork() succeeds.
pid_t fork(void) {
    errno = EAGAIN;
    return -1;
}
