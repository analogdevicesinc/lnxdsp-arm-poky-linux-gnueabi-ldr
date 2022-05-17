/*
 * File: ldr.c
 *
 * Copyright (c) 2006-2021, Analog Devices, Inc.  All rights reserved.

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
 * View LDR contents; based on the "Visual DSP++ 4.0 Loader Manual"
 * and misc Blackfin HRMs
 */

#include "ldr.h"

const char *argv0 = "ldr";
int force = 0, verbose = 0, quiet = 0, debug = 0;


struct option_help {
	const char *desc, *opts;
};

#define COMMON_FLAGS "fvqhV"
#define COMMON_LONG_OPTS \
	{"force",    no_argument, NULL, 'f'}, \
	{"verbose",  no_argument, NULL, 'v'}, \
	{"quiet",    no_argument, NULL, 'q'}, \
	{"debug",    no_argument, NULL, 0x1}, \
	{"help",     no_argument, NULL, 'h'}, \
	{"version",  no_argument, NULL, 'V'}, \
	{NULL,       no_argument, NULL, 0x0}
#define COMMON_HELP_OPTS \
	{"Ignore problems",          NULL}, \
	{"Make a lot of noise",      NULL}, \
	{"Only show errors",         NULL}, \
	{"Enable debugging",         NULL}, \
	{"Print this help and exit", NULL}, \
	{"Print version and exit",   NULL}, \
	{NULL,NULL}
#define CASE_common_errors \
	case 'f': ++force; break; \
	case 'v': ++verbose; break; \
	case 'q': ++quiet; break; \
	case 0x1: ++debug; break; \
	case 'V': show_version(argv0); \
	case ':': err("Option '%c' is missing parameter", optopt); \
	case '?': err("Unknown option '%c' or argument missing", (optopt ? : '?')); \
	default:  err("Unhandled option '%c'; please report this", i);

#define PARSE_FLAGS COMMON_FLAGS "sdlcT:f"
#define a_argument required_argument
static struct option const long_opts[] = {
	{"show",     no_argument, NULL, 's'},
	{"dump",     no_argument, NULL, 'd'},
	{"load",     no_argument, NULL, 'l'},
	{"create",   no_argument, NULL, 'c'},
	{"target",    a_argument, NULL, 'T'},
	{"proc",      a_argument, NULL, 0x2},
	{"si-revision",a_argument, NULL, 0x3},
	COMMON_LONG_OPTS
};
static struct option_help const opts_help[] = {
	{"Show details of a LDR",               "<ldrs>"},
	{"Break DXEs out of LDR",               "<ldrs>"},
	{"Load LDR (UART/network/USB/...)",     "<ldr> <devspec>"},
	{"Create LDR from binaries\n",          "<ldr> <elfs>"},
	{"Select LDR target",                   "<target>"},
	{"Select LDR target",                   "<target>"},
	{"Select Part's Silicon-Revision",      "<si-rev>"},
	COMMON_HELP_OPTS
};
#define show_usage(status) show_some_usage(argv0, NULL, long_opts, opts_help, PARSE_FLAGS, status)

#define SHOW_PARSE_FLAGS COMMON_FLAGS ""
static struct option const show_long_opts[] = {
	COMMON_LONG_OPTS
};
static struct option_help const show_opts_help[] = {
	COMMON_HELP_OPTS
};
#define show_show_usage(status) show_some_usage(argv0, "show", show_long_opts, show_opts_help, SHOW_PARSE_FLAGS, status)

#define DUMP_PARSE_FLAGS COMMON_FLAGS "F"
static struct option const dump_long_opts[] = {
	{"fill",     no_argument, NULL, 'F'},
	COMMON_LONG_OPTS
};
static struct option_help const dump_opts_help[] = {
	{"Dump fill sections as well",    NULL},
	COMMON_HELP_OPTS
};
#define show_dump_usage(status) show_some_usage(argv0, "dump", dump_long_opts, dump_opts_help, DUMP_PARSE_FLAGS, status)

#define CREATE_PARSE_FLAGS COMMON_FLAGS "p:g:d:B:w:H:s:b:i:P:MJ"
static struct option const create_long_opts[] = {
	{"bmode",     a_argument, NULL, 0x2},
	{"port",      a_argument, NULL, 'p'},
	{"gpio",      a_argument, NULL, 'g'},
	{"dma",       a_argument, NULL, 'd'},
	{"bits",      a_argument, NULL, 'B'},
	{"waitstate", a_argument, NULL, 'w'},
	{"holdtimes", a_argument, NULL, 'H'},
	{"spibaud",   a_argument, NULL, 's'},
	{"blocksize", a_argument, NULL, 'b'},
	{"initcode",  a_argument, NULL, 'i'},
	{"punchit",   a_argument, NULL, 'P'},
	{"use-vmas", no_argument, NULL, 'M'},
	{"no-jump",  no_argument, NULL, 'J'},
	{"nofillblock", no_argument, NULL, 0x4},
	{"core0",    no_argument, NULL, 0x3},
	{"bcode",     a_argument, NULL, 0x5},
	COMMON_LONG_OPTS
};
static struct option_help const create_opts_help[] = {
	{"(SC5xx & BF53x) Desired boot mode",   "<mode>"},
	{"(BF53x) PORT for HWAIT signal",       "<F|G|H>"},
	{"(BF53x) GPIO for HWAIT signal",       "<#>"},
	{"(BF54x) DMA flag",                    "<#>"},
	{"(BF56x) Flash bits (8bit)",           "<bits>"},
	{"(BF56x) Wait states (15)",            "<num>"},
	{"(BF56x) Flash Hold time cycles (3)",  "<num>"},
	{"(BF56x) SPI boot baud rate (500k)",   "<baud>"},
	{"Block size of DXE (0 = phdr size)",   "<size>"},
	{"Init code",                           "<file>"},
	{"Punch an ignore hole",                "<off:size[:filler]>"},
	{"Use ELF VMAs for target addresses",   NULL},
	{"Do not insert an L1 jump block",      NULL},
	{"Disable generating fill blocks",      NULL},
	{"Following dxes are for Core0",        NULL},
	{"(SC5xx) BCODE flags",                 "<#>"},
	COMMON_HELP_OPTS
};
#define show_create_usage(status) show_some_usage(argv0, "create", create_long_opts, create_opts_help, CREATE_PARSE_FLAGS, status)

#define LOAD_PARSE_FLAGS COMMON_FLAGS "b:CpD:"
static struct option const load_long_opts[] = {
	{"baud",          a_argument, NULL, 'b'},
	{"ctsrts",       no_argument, NULL, 'C'},
	{"prompt",       no_argument, NULL, 'p'},
	{"delay",         a_argument, NULL, 'D'},
	{"ack",          no_argument, NULL, 'a'},
	COMMON_LONG_OPTS
};
static struct option_help const load_opts_help[] = {
	{"Set baud rate (default 115200)",           "<baud>"},
	{"Enable hardware flow control",             NULL},
	{"Prompt for data flow",                     NULL},
	{"Interblock delay (1 second)",              "<usecs>"},
	{"Wait for block acknowledgement",           NULL},
	COMMON_HELP_OPTS
};
#define show_load_usage(status) show_some_usage(argv0, "load", load_long_opts, load_opts_help, LOAD_PARSE_FLAGS, status)

static void show_version(const char *argv0)
{
	printf("%s %s (built %s)\n", argv0, VERSION, __DATE__);
	exit(EXIT_SUCCESS);
}

static void show_some_usage(const char *argv0, const char *subcommand, struct option const opts[],
                            struct option_help const help[], const char *flags,
                            int exit_status)
{
	size_t i;

	if (subcommand)
		printf("Usage: %s --%s [options] <arguments>\n\n", argv0, subcommand);
	else
		printf("Usage: %s [options] <-s|-d|-l|-c> [subcommand options] <arguments>\n\n", argv0);
	printf("Options: -[%s]\n", flags);
	for (i = 0; opts[i].name; ++i) {
		if (!help[i].desc)
			err("someone forgot to update the help text");
		if (opts[i].val >= 0x10)
			printf("  -%c, ", opts[i].val);
		else
			printf("      ");
		printf("--%-15s %-15s * %s\n", opts[i].name,
		       (help[i].opts != NULL ? help[i].opts :
		          (opts[i].has_arg == no_argument ? "" : "<arg>")),
		       help[i].desc);
	}
	if (opts == long_opts)
		printf(
			"\n"
			"Most subcommands take their own arguments, so type:\n"
			"\tldr <subcommand> --help\n"
			"for help on a specific command.\n"
		);

	printf("\nSupported LDR targets:\n");
	lfd_target_list();

	exit(exit_status);
}


static bool show_ldr(const int argc, char *argv[], const char *target, const char *sirev)
{
	LFD *alfd = lfd_malloc(target, sirev);
	bool ret = true;
	int i;
	const char *filename;

	while ((i=getopt_long(argc, argv, SHOW_PARSE_FLAGS, show_long_opts, NULL)) != -1) {
		switch (i) {
			case 'h': show_show_usage(0);
			CASE_common_errors
		}
	}
	if (optind == argc)
		err("need at least one file to show");

	for (i = optind; i < argc; ++i) {
		filename = argv[i];
		if (!quiet)
			printf("Showing LDR %s ...\n", filename);
		if (!lfd_open(alfd, filename)) {
			warnp("unable to open LDR");
			ret &= false;
			continue;
		}
		if (!lfd_read(alfd)) {
			warnp("unable to read LDR");
			ret &= false;
		} else
			ret &= lfd_display(alfd);
		lfd_close(alfd);
	}
	return ret;
}

static bool dump_ldr(const int argc, char *argv[], const char *target, const char *sirev)
{
	LFD *alfd = lfd_malloc(target, sirev);
	bool ret = true;
	int i;

	struct ldr_dump_options opts = {
		.dump_fill = false,
	};

	while ((i=getopt_long(argc, argv, DUMP_PARSE_FLAGS, dump_long_opts, NULL)) != -1) {
		switch (i) {
			case 'F': opts.dump_fill = true; break;
			case 'h': show_dump_usage(0);
			CASE_common_errors
		}
	}
	if (optind == argc)
		err("need at least one LDR to dump");

	for (i = optind; i < argc; ++i) {
		opts.filename = argv[i];
		if (!quiet)
			printf("Dumping LDR %s ...\n", opts.filename);
		if (!lfd_open(alfd, opts.filename)) {
			warnp("unable to open LDR");
			ret &= false;
			continue;
		}
		if (!lfd_read(alfd)) {
			warnp("unable to read LDR");
			ret &= false;
		} else
			ret &= lfd_dump(alfd, &opts);
		lfd_close(alfd);
	}
	return ret;
}

static bool load_ldr(const int argc, char *argv[], const char *target, const char *sirev)
{
	LFD *alfd = lfd_malloc(target, sirev);
	bool ret = true;
	int i;
	const char *filename;

	struct ldr_load_options opts = {
		.dev = NULL,
		.baud = 115200,
		.ctsrts = false,
		.prompt = false,
		.sleep_time = 1000000,
		.ack = false,
	};

	while ((i=getopt_long(argc, argv, LOAD_PARSE_FLAGS, load_long_opts, NULL)) != -1) {
		switch (i) {
			case 'b': opts.baud = atoi(optarg); break;
			case 'C': opts.ctsrts = true; break;
			case 'p': opts.prompt = true; break;
			case 'D': opts.sleep_time = atoi(optarg); break;
			case 'a': opts.ack = true; break;
			case 'h': show_load_usage(0);
			CASE_common_errors
		}
	}
	if (optind + 2 != argc)
		err("Load requires two arguments: <ldr> <devspec>");

	filename = argv[optind];
	opts.dev = argv[optind+1];

	if (!quiet)
		printf("Loading LDR %s ... ", filename);
	if (!lfd_open(alfd, filename)) {
		printf("\n");
		warnp("unable to open LDR");
		ret &= false;
	} else {
		if (!lfd_read(alfd)) {
			warnp("unable to read LDR");
			ret &= false;
		} else {
			if (!quiet)
				printf("OK!\n");
			ret &= lfd_load(alfd, &opts);
		}
		lfd_close(alfd);
	}
	return ret;
}

/* Very strict char* to unsigned int function.  Accepts hex (0x*) and
 * decimal formats only.  Aborts at the slightest hint of trouble. */
static uint32_t read_number(char *optarg){
	uint32_t ret = 0;
	bool fail = true;
	bool hex = false;
	int i = 0;
	if (optarg[0] == '0' && (optarg[1] == 'x' || optarg[1] == 'X'))
		hex = true;
	if (hex)
		i = 2;
	/* First scan through for bad characters */
	while (optarg[i] != 0){
		if (isdigit(optarg[i]) /* 0 - 9 */
		    ||
		    (hex /* if hex, also accept a-f and A-F */
		     &&
		     ((optarg[i] >= 0x41 /* A */
               && optarg[i] <= 0x46 /* F */)
		      ||
		      (optarg[i] >= 0x61 /* a */
               && optarg[i] <= 0x66 /* f */)))) {
			/* Success, continue. */
			i++;
		} else {
			/* We found a bad char.  Abort. */
			printf("Character '%c' not valid in input: %s\n", optarg[i], optarg);
			exit(EXIT_FAILURE);
		}
	}
	if (hex) {
		sscanf(optarg, "%X", &ret);
		if(ret != EOF)
			fail = false;
	} else {
		/* if not hex, decimal */
		ret = atoi(optarg);
		if(ret != 0 || optarg[0] == 0x30)
			fail = false;
	}
	
	if (fail) {
		/*FAIL and bail. */
		printf("Couldn't decode number: %s\n", optarg);
		exit(EXIT_FAILURE);
	}
	return ret;
}

static bool create_ldr(const int argc, char **argv, const char *target, const char *sirev)
{
	LFD *alfd = lfd_malloc(target, sirev);
	bool ret = true;
	int i;

	struct ldr_create_options opts = {
		.bmode = NULL,
		.port = '?',
		.gpio = 0,
		.dma = 1,
		.flash_bits = 8,
		.wait_states = 15,
		.flash_holdtimes = 3,
		.spi_baud = 500,
		.block_size = 0x8000,
		.init_code = NULL,
		.hole = { 0, 0, NULL },
		.use_vmas = false,
		.jump_block = true,
		.fill_blocks = true,
		.cur_core = 0,
		.filelist = NULL,
		.bcode = 0,
	};

	while ((i=getopt_long(argc, argv, CREATE_PARSE_FLAGS, create_long_opts, NULL)) != -1) {
		switch (i) {
			case 0x2: opts.bmode = optarg; break;
			case 'p': opts.port = toupper(optarg[0]); break;
			case 'g': opts.gpio = atoi(optarg); break;
			case 'd': opts.dma = atoi(optarg); break;
			case 0x5:
				/* support reading in hex values since it's much more
				 * common for people to set size in terms of hex ...
				 */
				opts.bcode = read_number(optarg);
				if (opts.bcode > 15)
					err("Invalid bcode '%d' specified.", opts.bcode);
				break;
			case 'B': opts.flash_bits = atoi(optarg); break;
			case 'w': opts.wait_states = atoi(optarg); break;
			case 'H': opts.flash_holdtimes = atoi(optarg); break;
			case 's': opts.spi_baud = atoi(optarg); break;
			case 'b':
				/* support reading in hex values since it's much more
				 * common for people to set size in terms of hex ...
				 */
				opts.block_size = read_number(optarg);
				if (opts.block_size == 0 || opts.block_size % 4)
					err("Invalid block size '%d' specified.", opts.block_size);
				break;
			case 'i': opts.init_code = optarg; break;
			case 'P':
				/* support reading in hex values since it's much more
				 * common for people to set size in terms of hex ...
				 */
				if (sscanf(optarg, "%zi:%zi", &opts.hole.offset, &opts.hole.length) != 2)
					if (sscanf(optarg, "%zX:%zX", &opts.hole.offset, &opts.hole.length) != 2)
						err("Unable to parse offset:size from '%s'", optarg);

				/* if the filler option was specified, grab the filename */
				char *filler_file = strchr(optarg, ':');
				if (filler_file) {
					filler_file = strchr(filler_file + 1, ':');
					if (filler_file++) {
						if (access(filler_file, R_OK))
							err("Unable to access filler file '%s'", filler_file);
						opts.hole.filler_file = filler_file;
					}
				}
				break;
			case 'M': opts.use_vmas = true; break;
			case 'J': opts.jump_block = false; break;
			case 0x4: opts.fill_blocks = false; break;
			case 0x3: opts.cur_core = 0; break;
			case 'h': show_create_usage(0);
			CASE_common_errors
		}
	}
	if (argc < optind + 2)
		err("Create requires at least two arguments: <ldr> <elfs>");
	if (strchr("?FGH", opts.port) == NULL)
		err("Invalid PORT '%c'.  Valid PORT values are 'F', 'G', and 'H'.", opts.port);
	if (opts.gpio > 16)
		err("Invalid GPIO '%i'.  Valid GPIO values are 0 - 16.", opts.gpio);
	if (opts.dma < 1 || opts.dma > 15)
		err("Invalid DMA '%i'.  Valid DMA values are 1 - 15.", opts.dma);
	if (opts.flash_bits != 8 && opts.flash_bits != 16)
		err("Invalid flash bits '%i'.  Valid bits are '8' and '16'.", opts.flash_bits);
	if (opts.wait_states > 15)
		err("Invalid number of wait states '%i'.  Valid values are 0 - 15.", opts.wait_states);
	if (opts.flash_holdtimes > 3)
		err("Invalid number of flash hold time cycles '%i'.  Valid values are 0 - 3.", opts.flash_holdtimes);
	if (opts.spi_baud != 500 && opts.spi_baud != 1000 && opts.spi_baud != 2000)
		err("Invalid SPI baud '%i'.  Valid values are 500 (500k), 1000 (1M), or 2000 (2M).", opts.spi_baud);
	if (opts.init_code && access(opts.init_code, R_OK))
		errp("Unable to read initcode '%s'", opts.init_code);

	opts.filelist = argv + optind;

	if (!quiet)
		printf("Creating LDR %s ...\n", *(argv+optind));
	if (!lfd_open(alfd, NULL)) {
		warnp("Unable to init lfd");
		ret &= false;
	} else if (!lfd_create(alfd, &opts)) {
		perror("Failed to create LDR");
		ret &= false;
	} else if (!quiet)
		printf("Done!\n");
	return ret;
}


static void prog_failure_signaled(int sig)
{
	/* strsignal() is not portable */
	const char *signame;
	switch (sig) {
		case SIGSEGV: signame = "SIGSEGV"; break;
		case SIGILL:  signame = "SIGILL"; break;
		default:      signame = "???"; break;
	}
	printf("\n\nLDR failed at life after receiving signal %i (%s)!\n"
		"Please report this in order to get it fixed\n", sig, signame);

#ifdef HAVE_FORK
	/* auto launch gdb! */
	if (debug) {
		pid_t crashed_pid = getpid();
		switch (fork()) {
			case -1: break;
			case 0: {
				int ret;
				char pid[10];
				snprintf(pid, sizeof(pid), "%i", crashed_pid);
				printf("\nAuto launching gdb!\n\n");
				ret = execlp("gdb", "gdb", "--quiet", "--pid", pid, "-ex", "bt full", NULL);
				_exit(ret);
			}
			default: {
				int status;
				wait(&status);
			}
		}
	} else
#endif
		error_backtrace();

	_exit(1);
}


#define set_action(action) \
	do { \
		if (a != NONE) \
			err("Cannot specify more than one action at a time"); \
		a = action; \
	} while (0)
#define reload_sub_args(new_argv0) \
	do { \
		--optind; \
		argc -= optind; \
		argv += optind; \
		optind = 0; \
		argv[0] = new_argv0; \
	} while (0)

int main(int argc, char *argv[])
{
	typedef enum { SHOW, DUMP, LOAD, CREATE, NONE } actions;
	actions a = NONE;
	const char *lfd_target = NULL;
	const char *lfd_sirev = NULL;
	bool ret = true;
	int i;

	signal(SIGSEGV, prog_failure_signaled);
	signal(SIGILL, prog_failure_signaled);

	argv0 = strrchr(argv[0], '/');
	argv0 = (argv0 == NULL ? argv[0] : argv0+1);

	while ((i=getopt_long(argc, argv, PARSE_FLAGS, long_opts, NULL)) != -1) {
		switch (i) {
			case 's': set_action(SHOW); goto parse_action;
			case 'd': set_action(DUMP); goto parse_action;
			case 'l': set_action(LOAD); goto parse_action;
			case 'c': set_action(CREATE); goto parse_action;
			case 0x2:
			case 'T': lfd_target = optarg; break;
			case 0x3: lfd_sirev = optarg; break;
			case 'h': show_usage(0);
			CASE_common_errors
		}
	}
	if (optind == argc)
		show_usage(EXIT_FAILURE);

 parse_action:

	switch (a) {
		case SHOW:
			reload_sub_args("show");
			ret &= show_ldr(argc, argv, lfd_target, lfd_sirev);
			break;
		case DUMP:
			reload_sub_args("dump");
			ret &= dump_ldr(argc, argv, lfd_target, lfd_sirev);
			break;
		case LOAD:
			reload_sub_args("load");
			ret &= load_ldr(argc, argv, lfd_target, lfd_sirev);
			break;
		case CREATE:
			reload_sub_args("create");
			ret &= create_ldr(argc, argv, lfd_target, lfd_sirev);
			break;
		case NONE:
			/* guess at requested action based upon context
			 *  - one argument: show ldr
			 *  - two arguments, second is a char device: load ldr
			 */
			if (argc - optind == 1)
				a = SHOW;
			else if (argc - optind == 2) {
				struct stat st;
				if (stat(argv[optind+1], &st) == 0) {
					if (S_ISCHR(st.st_mode))
						a = LOAD;
				}
			}
			if (a != NONE)
				goto parse_action;
			show_usage(EXIT_FAILURE);
	}

	return (ret ? EXIT_SUCCESS : EXIT_FAILURE);
}
