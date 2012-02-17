// modules: vte-2.90

using GLib;
using Gtk;
using Vte;

class taterm : Gtk.Application
{
	string pwd = GLib.Environment.get_home_dir();

	public taterm()
	{
		Object(application_id: "de.t-8ch.taterm");
		hold();

		activate.connect(() => {
			var newWin = new Window(pwd);
			add_window(newWin);
			newWin.pwd_changed.connect((newpwd) => {
				this.pwd = newpwd;
			});
		});
	}

	public static int main(string[] args)
	{
		Gtk.init(ref args);
		return new taterm().run();
	}

	class Window : Gtk.Window
	{
		Vte.Terminal term;
		GLib.Pid shell;
		string pwd;
		string[] targs;

		public signal void pwd_changed(string pwd);

		public Window(string pwd)
		{
			this.pwd = pwd;

			/*
			   This throws a compiler warning
			   new Vte.Terminal returns a Gtk.Widget,
			   which is instantly cast to Vte.Terminal
			   Seems there is no chance to avoid this
			   (Maybe writing a own subclass, works for Gtk.Window)
			*/
			term = new Terminal();

			this.has_resize_grip = false;
			targs = { Vte.get_user_shell() };

			try {
				term.fork_command_full(0, pwd, targs, null, 0, null, out shell);
			} catch (Error err) {
				stderr.printf(err.message);
			}

			term.child_exited.connect ( ()=> {
				this.destroy();
			});

			term.window_title_changed.connect ( ()=> {
				this.title = term.window_title;
				var newpwd = Utils.cwd_of_pid(shell);

				if (newpwd != pwd) {
					this.pwd = newpwd;
					pwd_changed(this.pwd);
				}
			});

			this.add(term);
			this.show_all();
		}
	}

	class Terminal : Vte.Terminal {

		/* TODO
		   make more general, want to get as many URIs as possible
		   */
		string regex_string = "[^ \n\r\t]*://.*[^ \n\r\t]";
		// string regex_string = "((f|F)|(h|H)(t|T))(t|T)(p|P)(s|S)?://(([^|.< \t\r\n\\\"]*([.][^|< \t\r\n\\\"])?[^|.< \t\r\n\\\"]*)*[^< \t\r\n,;|\\\"]*[^|.< \t\r\n\\\"])?/*";
		GLib.Regex uri_regex;

		public Terminal() {
			set_cursor_blink_mode(Vte.TerminalCursorBlinkMode.OFF);
			this.scrollback_lines = -1; /* infinity */

			try {
				uri_regex = new GLib.Regex(regex_string);
			} catch (Error err) {
				stderr.printf(err.message);
			}
			this.match_add_gregex(uri_regex, 0);
		}

	}

	class Utils
	{
		public static string cwd_of_pid(GLib.Pid pid)
		{
			var cwdlink = "/proc/%d/cwd".printf(pid);
			try {
				return GLib.FileUtils.read_link(cwdlink);
			} catch (Error err) {
				stderr.printf(err.message);
			}
			return GLib.Environment.get_home_dir();
		}
	}
}
