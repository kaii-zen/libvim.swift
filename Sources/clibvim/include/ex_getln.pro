/* ex_getln.c */

void *state_cmdline_initialize(int c, long count UNUSED, int indent);
executionStatus_T state_cmdline_execute(void *ctx, int c);
void state_cmdline_cleanup(void *context);

void cmdline_init(void);
char_u *getcmdline(int firstc, long count, int indent);
char_u *getcmdline_prompt(int firstc, char_u *prompt, int attr, int xp_context,
                          char_u *xp_arg);
int text_locked(void);
void text_locked_msg(void);
char *get_text_locked_msg(void);
int curbuf_locked(void);
int allbuf_locked(void);
char_u *getexline(int c, void *cookie, int indent);
char_u *getexmodeline(int promptc, void *cookie, int indent);
int cmdline_overstrike(void);
int cmdline_at_end(void);
colnr_T cmdline_getvcol_cursor(void);
void free_cmdline_buf(void);
void putcmdline(int c, int shift);
void unputcmdline(void);
int put_on_cmdline(char_u *str, int len, int redraw);
void cmdline_paste_str(char_u *s, int literally);
void redrawcmdline(void);
void redrawcmdline_ex(int do_compute_cmdrow);
void redrawcmd(void);
void compute_cmdrow(void);
void gotocmdline(int clr);
char_u *ExpandOne(expand_T *xp, char_u *str, char_u *orig, int options,
                  int mode);
void ExpandInit(expand_T *xp);
void ExpandCleanup(expand_T *xp);
void ExpandEscape(expand_T *xp, char_u *str, int numfiles, char_u **files,
                  int options);
char_u *vim_strsave_fnameescape(char_u *fname, int shell);
void tilde_replace(char_u *orig_pat, int num_files, char_u **files);
char_u *sm_gettail(char_u *s);
char_u *addstar(char_u *fname, int len, int context);
void set_cmd_context(expand_T *xp, char_u *str, int len, int col,
                     int use_ccline);
int expand_cmdline(expand_T *xp, char_u *str, int col, int *matchcount,
                   char_u ***matches);
int ExpandGeneric(expand_T *xp, regmatch_T *regmatch, int *num_file,
                  char_u ***file, char_u *((*func)(expand_T *, int)),
                  int escaped);
void globpath(char_u *path, char_u *file, garray_T *ga, int expand_options);
void init_history(void);
int get_histtype(char_u *name);
void add_to_history(int histype, char_u *new_entry, int in_map, int sep);
int get_history_idx(int histype);
char_u *get_history_entry(int histype, int idx);
int clr_history(int histype);
int del_history_entry(int histype, char_u *str);
int del_history_idx(int histype, int idx);
char_u *get_cmdline_str(void);
int get_cmdline_pos(void);
int set_cmdline_pos(int pos);
int get_cmdline_type(void);
int get_list_range(char_u **str, int *num1, int *num2);
void ex_history(exarg_T *eap);
void prepare_viminfo_history(int asklen, int writing);
int read_viminfo_history(vir_T *virp, int writing);
void handle_viminfo_history(garray_T *values, int writing);
void finish_viminfo_history(vir_T *virp);
void write_viminfo_history(FILE *fp, int merge);
char_u *script_get(exarg_T *eap, char_u *cmd);
/* vim: set ft=c : */
