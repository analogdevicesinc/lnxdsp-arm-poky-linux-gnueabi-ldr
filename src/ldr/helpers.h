/*
 * File: helpers.h
 *
 * Copyright (c) 2006-2014, Analog Devices, Inc.  All rights reserved.

 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted (subject to the limitations in the
 * disclaimer below) provided that the following conditions are met:
 *
 * * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 * * Neither the name of Analog Devices, Inc.  nor the names of its
 *    contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * NO EXPRESS OR IMPLIED LICENSES TO ANY PARTY'S PATENT RIGHTS ARE
 * GRANTED BY THIS LICENSE.  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT
 * HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Description:
 * some common utility functions
 */

#ifndef __HELPERS_H__
#define __HELPERS_H__

#ifndef VERSION
# define VERSION "live"
#endif

extern int force, verbose, quiet, debug;

extern const char *argv0;

#if defined(__GLIBC__) && !defined(__UCLIBC__) && !defined(NDEBUG)
# define HAVE_BACKTRACE
void error_backtrace(void);
void error_backtrace_maybe(void);
#else
# define error_backtrace()
# define error_backtrace_maybe()
#endif

#define warn(fmt, args...) \
	fprintf(stderr, "%s: " fmt "\n", argv0 , ## args)
#define warnf(fmt, args...) warn("%s(): " fmt, __func__ , ## args)
#define warnp(fmt, args...) warn(fmt ": %s" , ## args , strerror(errno))
#define _err(wfunc, fmt, args...) \
	do { \
		wfunc(fmt, ## args); \
		error_backtrace_maybe(); \
		exit(EXIT_FAILURE); \
	} while (0)
#define err(fmt, args...) _err(warn, fmt, ## args)
#define errf(fmt, args...) _err(warnf, fmt, ## args)
#define errp(fmt, args...) _err(warnp, fmt , ## args)

#define container_of(ptr, type, member) \
	({ \
		const typeof( ((type *)0)->member ) *__mptr = (ptr); \
		(type *)( (char *)__mptr - offsetof(type,member) ); \
	})
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))

void *xmalloc(size_t);
void *xzalloc(size_t);
void *xrealloc(void *, size_t);
char *xstrdup(const char *);
bool parse_bool(const char *);
ssize_t read_retry(int, void *, size_t);
size_t fread_retry(void *, size_t, size_t, FILE *);

size_t tty_get_baud(const int);
int tty_open(const char *, int);
bool tty_init(const int, const size_t, const bool);
bool tty_lock(const char *);
bool tty_unlock(const char *);
void tty_stdin_init(void);

#ifndef HAVE_ALARM
# define alarm(seconds) 0
# define SIGALRM 0
#endif
#ifndef HAVE_FDATASYNC
# define fdatasync(fd) 0
#endif
#ifndef HAVE_USLEEP
# define usleep(usecs) 0
#endif

#ifndef HAVE_PTHREAD_H
typedef int pthread_t;
# define pthread_cancel(thread)
# define pthread_create(thread, attr, func, arg)
#endif

#endif
