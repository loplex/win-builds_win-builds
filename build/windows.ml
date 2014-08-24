let builder ~cross ~name ~host =
  let open Config in
  let build = Arch.slackware in
  let prefix = Prefix.t ~build ~host ~target:host in
  let logs, yyoutput = Builder.logs_yyoutput ~nickname:prefix.Prefix.nickname in
  cross.Config.Builder.target_prefix <- Some prefix.Prefix.yyprefix;
  let open Arch in
  let open Prefix in
  let open Builder in
  {
    name;
    prefix; logs; yyoutput;
    path = Env.Prepend [ bindir cross.prefix; bindir Native_toolchain.builder.prefix ];
    pkg_config_path = Env.Clear;
    pkg_config_libdir = Env.Set [ Filename.concat prefix.libdir "pkgconfig" ] ;
    tmp = Env.Set [ Filename.concat prefix.Prefix.yyprefix "tmp" ];
    target_prefix = None; native_prefix = Some Native_toolchain.builder.prefix.Prefix.yyprefix;
    packages = [];
  }

let do_adds builder =
  let add = Config.Builder.register ~builder in

  let xz ~variant ~dependencies =
    add ("xz", Some variant)
      ~dir:"slackware64-current/a"
      ~dependencies
      ~version:"5.0.5"
      ~build:1
      ~sources:[
        "xz-${VERSION}.tar.xz"
      ]
  in

  let libarchive ~variant ~dependencies =
    add ("libarchive", Some variant)
      ~dir:"slackware64-current/l"
      ~dependencies
      ~version:"3.1.2"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
  in

  let efl ~variant ~dependencies =
    add ("efl", Some variant)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies
      ~version:"1.11.0-beta1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
  in

  let elementary ~variant ~dependencies =
    add ("elementary", Some variant)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies
      ~version:"1.11.0-beta1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
  in

  let libjpeg ~variant ~dependencies =
    add ("libjpeg", Some variant)
      ~dir:"slackware64-current/l"
      ~dependencies
      ~version:"v9a"
      ~build:2
      ~sources:[
        "jpegsrc.${VERSION}.tar.gz"
      ]
  in

  let zlib ~variant ~dependencies =
    add ("zlib", Some variant)
      ~dir:"slackware64-current/l"
      ~dependencies
      ~version:"1.2.8"
      ~build:1
      ~sources:[
        "zlib-${VERSION}.tar.xz"
      ]
  in

  let lua ~variant ~dependencies =
    add ("lua", Some variant)
      ~dir:"slackbuilds.org/development"
      ~dependencies
      ~version:"5.1.5"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
  in

  let freetype ~variant ~dependencies =
    add ("freetype", Some variant)
      ~dir:"slackware64-current/l"
      ~dependencies
      ~version:"2.5.0.1"
      ~build:1
      ~sources:[
        "freetype-${VERSION}.tar.xz";
        "freetype.illadvisederror.diff.gz";
        "freetype.subpixel.rendering.diff.gz";
      ]
  in

  let expat ~variant ~dependencies =
    add ("expat", Some variant)
      ~dir:"slackware64-current/l"
      ~dependencies
      ~version:"2.1.0"
      ~build:1
      ~sources:[
        "expat-${VERSION}.tar.xz"
      ]
  in

  let dbus ~variant ~dependencies =
    add ("dbus", Some variant)
      ~dir:"slackware64-current/a"
      ~dependencies
      ~version:"1.6.12"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
  in

  let _yypkg =
    let variant = "yypkg" in

    let libjpeg = libjpeg ~variant ~dependencies:[] in

    let zlib = zlib ~variant ~dependencies:[] in

    let lua = lua ~variant ~dependencies:[] in

    let freetype = freetype ~variant ~dependencies:[ zlib ] in

    let expat = expat  ~variant ~dependencies:[] in

    let dbus = dbus ~variant ~dependencies:[ expat ] in

    let xz = xz ~variant ~dependencies:[] in

    let libarchive = libarchive ~variant ~dependencies:[] in

    let efl = efl ~variant ~dependencies:[ dbus; freetype; lua; zlib; libjpeg ] in

    let elementary = elementary ~variant ~dependencies:[ efl ] in

    let ocaml_cryptokit = add ("ocaml-cryptokit", None)
      ~dir:"slackbuilds.org/ocaml"
      ~dependencies:[]
      ~version:"1.9"
      ~build:1
      ~sources:[
        "cryptokit-${VERSION}.tar.gz"
      ]
    in

    add ("yypkg", None)
      ~dir:""
      ~dependencies:[
        xz; libarchive; elementary; ocaml_cryptokit
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]

  in

  let _all =
    let mingw_w64_tool_add name = add (name, None)
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"v3.1.0"
      ~build:1
      ~sources:[
        "mingw-w64-${VERSION}.tar.bz2"
      ]
    in

    let winpthreads = add ("winpthreads", None)
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"v3.1.0"
      ~build:2
      ~sources:[
        "mingw-w64-${VERSION}.tar.bz2"
      ]
    in

    let gendef = mingw_w64_tool_add "gendef" in

    let genidl = mingw_w64_tool_add "genidl" in

    let genpeimg = mingw_w64_tool_add "genpeimg" in

    let widl = mingw_w64_tool_add "widl" in

    let win_iconv = add ("win-iconv", None)
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"0.0.6"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2"
      ]
    in

    let gettext = add ("gettext", None)
      ~dir:"slackware64-current/a"
      ~dependencies:[ win_iconv ]
      ~version:"0.18.3.1"
      ~build:2
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
    in

    let xz = xz ~variant:"regular" ~dependencies:[ gettext ] in

    let zlib = zlib ~variant:"regular" ~dependencies:[] in

    let libjpeg = libjpeg ~variant:"regular" ~dependencies:[] in

    let expat = expat ~variant:"regular" ~dependencies:[] in

    let libpng = add ("libpng", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ zlib ]
      ~version:"1.4.12"
      ~build:1
      ~sources:[
        "libpng-${VERSION}.tar.xz"
      ]
    in

    let freetype = freetype ~variant:"regular" ~dependencies:[ zlib; libpng ] in

    let fontconfig = add ("fontconfig", None)
      ~dir:"slackware64-current/x"
      ~dependencies:[ freetype; expat ]
      ~version:"2.11.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
    in

    let giflib = add ("giflib", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"4.1.6"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let libtiff = add ("libtiff", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ libjpeg ]
      ~version:"3.9.7"
      ~build:1
      ~sources:[
        "tiff-${VERSION}.tar.xz";
        "tiff-${VERSION}_CVE-2012-4447_CVE-2012-4564_CVE-2013-1960_CVE-2013-1961.diff.gz";
        "tiff-${VERSION}_CVE-2013-4231.diff.gz";
        "tiff-${VERSION}_CVE-2013-4232.diff.gz";
        "tiff-${VERSION}_CVE-2013-4244.diff.gz";
      ]
    in

    let lua = lua ~variant:"regular" ~dependencies:[] in

    let ca_certificates = add ("ca-certificates", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[]
      ~version:"20130906"
      ~build:1
      ~sources:[
        "${PACKAGE}_${VERSION}.tar.gz"
      ]
    in

    let openssl = add ("openssl", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[ ca_certificates ]
      ~version:"1.0.1i"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
    in

    let gmp = add ("gmp", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"5.1.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let nettle = add ("nettle", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[]
      ~version:"2.7.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let libtasn1 = add ("libtasn1", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"3.6"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let gnutls = add ("gnutls", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[ zlib; gmp; libtasn1; nettle; ca_certificates ]
      ~version:"3.2.15"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let curl = add ("curl", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[ ca_certificates ]
      ~version:"7.36.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2"
      ]
    in

    let c_ares = add ("c-ares", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"1.10.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz"
      ]
    in

    let pixman = add ("pixman", None)
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"0.32.6"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let libffi = add ("libffi", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"3.0.13"
      ~build:2
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let glib2 = add ("glib2", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ libffi ]
      ~version:"2.36.4"
      ~build:1
      ~sources:[
        "glib-${VERSION}.tar.xz"
      ]
    in

    let cairo = add ("cairo", None)
      ~dir:"slackware64-current/l"
      (* TODO: seems to be able to use pthread *)
      ~dependencies:[ pixman; freetype; fontconfig; libpng ]
      ~version:"1.12.16"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let atk = add ("atk", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"2.8.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let pango = add ("pango", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"1.34.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz"
      ]
    in

    let gdk_pixbuf2 = add ("gdk-pixbuf2", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"2.28.2"
      ~build:1
      ~sources:[
        "gdk-pixbuf-${VERSION}.tar.xz";
        "gdk-pixbuf.pnglz.diff.gz";
      ]
    in

    let gtk_2 =
      let dir =
        if Config.(builder.Builder.prefix.Prefix.host = Arch.windows_64) then
          ""
        else
          "slackware64-current/l"
      in
      add ("gtk+2", None)
        ~dir
        ~dependencies:[ gdk_pixbuf2; pango; atk; cairo; glib2 ]
        ~version:"2.24.20"
        ~build:1
        ~sources:[
          "gtk+-${VERSION}.tar.xz";
          "gtk+-2.24.x.icon-compat.am.diff.gz";
          "gtk+-2.24.x.icon-compat.diff.gz";
        ]
    in

    let glib_networking = add ("glib-networking", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ glib2 ]
      ~version:"2.36.2"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libxml2 = add ("libxml2", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"2.9.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let sqlite = add ("sqlite", None)
      ~dir:"slackware64-current/ap"
      ~dependencies:[]
      ~version:"3071700"
      ~build:1
      ~sources:[
        "${PACKAGE}-src-3071700.tar.xz";
        "COPYRIGHT.gz";
        "configure.ac";
      ]
    in

    let libsoup = add ("libsoup", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ glib2; sqlite ]
      ~version:"2.42.2"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let icu4c = add ("icu4c", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"51.2" (* NOTE: the version number in sources needs updating too *)
      ~build:2
      ~sources:[
        "${PACKAGE}-51_2-src.tar.xz";
      ]
    in

    let gperf = add ("gperf", None)
      ~dir:"slackware64-current/d"
      ~dependencies:[]
      ~version:"3.0.4"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let mpfr = add ("mpfr", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"3.1.2"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libmpc = add ("libmpc", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"0.8.2"
      ~build:2
      ~sources:[
        "mpc-${VERSION}.tar.xz";
      ]
    in

    let libogg = add ("libogg", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"1.3.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libvorbis = add ("libvorbis", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ libogg ]
      ~version:"1.3.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libtheora = add ("libtheora", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ libvorbis ]
      ~version:"1.1.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let fribidi = add ("fribidi", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"0.19.2"
      ~build:3
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libsndfile = add ("libsndfile", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"1.0.25"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let dbus = dbus ~variant:"regular" ~dependencies:[ expat ] in

    let harfbuzz = add ("harfbuzz", None)
      ~dir:"slackware64-current/l"
      (* TODO: the cairo dependency is only build-time; what about the others? *)
      ~dependencies:[ cairo; freetype; glib2; icu4c ]
      ~version:"0.9.16"
      ~build:2
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let efl = efl ~variant:"regular" ~dependencies:[
      libtiff; libpng; giflib; libjpeg;
      fontconfig; freetype; lua;
      fribidi; harfbuzz; libsndfile;
      gnutls; curl; c_ares; dbus;
    ]
    in

    let elementary = elementary ~variant:"regular" ~dependencies:[ efl ] in

    let pkg_config = add ("pkg-config", None)
      ~dir:"slackware64-current/d"
      ~dependencies:[]
      ~version:"0.25"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libarchive = libarchive ~variant:"yypkg" ~dependencies:[] in

    let wget = add ("wget", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[ openssl ]
      ~version:"1.14"
      ~build:2
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let mingw_w64 = add ("mingw-w64", Some "full")
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"v3.1.0"
      ~build:2
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    let binutils = add ("binutils", None)
      ~dir:"slackware64-current/d"
      ~dependencies:[]
      ~version:"2.24"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
        "binutils.export.demangle.h.diff.gz";
        "binutils.no-config-h-check.diff.gz";
      ]
    in

    let gcc = add ("gcc", Some "full")
      ~dir:"slackware64-current/d"
      ~dependencies:[ gmp; mpfr; libmpc ]
      ~version:"4.8.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let x264 = add ("x264", None)
      ~dir:"slackbuilds.org/multimedia"
      ~dependencies:[]
      ~version:"20131101"
      ~build:1
      ~sources:[
        "${PACKAGE}-snapshot-${VERSION}-2245-stable.tar.bz2";
      ]
    in

    let pcre = add ("pcre", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"8.33"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libao = add ("libao", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"1.1.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let flac = add ("flac", None)
      ~dir:"slackware64-current/ap"
      ~dependencies:[ libao (* TODO: check *) ]
      ~version:"1.2.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
        "flac.gcc45.diff.gz";
        "flac.man.diff.gz";
      ]
    in

    let gdb = add ("gdb", None)
      ~dir:"slackware64-current/d"
      ~dependencies:[]
      ~version:"7.8"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libmad = add ("libmad", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"0.15.1b"
      ~build:3
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
        "Makefile.am";
        "configure.ac";
        "mad.pc.in";
      ]
    in

    let libid3tag = add ("libid3tag", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"0.15.1b"
      ~build:4
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let madplay = add ("madplay", None)
      ~dir:"slackware64-current/ap"
      ~dependencies:[ libid3tag; libmad ]
      ~version:"0.15.2b"
      ~build:4
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
        "${PACKAGE}-${VERSION}-fix-segfault.patch.gz";
      ]
    in

    let lcms = add ("lcms", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ zlib; libtiff; libjpeg ]
      ~version:"1.19"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let lcms2 = add ("lcms2", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"2.4"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let djvulibre = add ("djvulibre", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"3.5.25.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
        "patches/0047-djvused-added-missing-command-remove-outline.patch";
        "patches/0053-portable-pthread_t-initialization.patch";
        "patches/0056-remove-extra-semi-in-test-for-std-c-includes.patch";
        "patches/0058-fixed-for-mingw.patch";
        "patches/0059-Attempt-to-work-around-typename-issues.patch";
        "patches/0060-more-mingw-fixes.patch";
        "patches/0061-removed-gstring-cruft.patch";
        "patches/0063-windows-recompile-reveals-issues.patch";
        "patches/0072-handle-period-in-crlf-files-as-well.patch";
        "patches/0077-fix-for-filename-conversion.patch";
        "patches/0079-locale-changes-for-win32.patch";
        "patches/0088-fixed-trivial-crash.patch";
        "patches/0094-meta-data-metadata.patch";
        "patches/0105-Fixed-small-bugs-from-Maks.patch";
        "patches/0107-Added-the-magic-win32-dll-option-in-LT_INIT-see-bug-.patch";
        "patches/0108-Cast-pointers-to-size_t-instead-of-unsigned-long.patch";
        "patches/0109-Added-code-to-define-inline-when-using-C.patch";
        "patches/0115-Fixed-clang-warnings.patch";
      ]
    in

    let dejavu_fonts_ttf = add ("dejavu-fonts-ttf", None)
      ~dir:"slackware64-current/x"
      ~dependencies:[]
      ~version:"2.34"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let opus = add ("opus", None)
      ~dir:"slackbuilds.org/audio"
      ~dependencies:[]
      ~version:"1.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let a52dec = add ("a52dec", None)
      ~dir:"slackbuilds.org/audio"
      ~dependencies:[]
      ~version:"0.7.4"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let libmpeg2 = add ("libmpeg2", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"0.5.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let libsigc_plus_plus = add ("libsigc++", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"2.2.11"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let jansson = add ("jansson", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"2.5"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    (* let opencore_amr = add ("opencore-amr", None)
      ~dir:"slackbuilds.org/audio"
      ~dependencies:[]
      ~version:"0.1.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in *)

    (* let faad2 = add ("faad2", None)
      ~dir:"slackbuilds.org/audio"
      ~dependencies:[]
      ~version:"2.7"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in *)

    let lame = add ("lame", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"3.99.5"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let qt = add ("qt", Some "regular")
      ~dir:"slackware64-current/l"
      ~dependencies:[ icu4c; zlib; sqlite; pcre; libpng; libjpeg; harfbuzz; dbus;
        (* freetype; (* build with -system-freetype is broken and probably unsupported *) *)
        (* win_iconv (* disabled by default in the build *) *)
        (* giflib (* Qt never uses the sytem one! *) *)
      ]
      ~version:"5.3.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-everywhere-opensource-src-${VERSION}.tar.gz";
        "0001-configure-use-pkg-config-for-libpng.patch";
        "0001-windployqt-Fix-cross-compilation.patch";
        "0002-Use-widl-instead-of-midl.-Also-set-QMAKE_DLLTOOL-to-.patch";
        "0003-Tell-qmake-to-use-pkg-config.patch";
        "Qt.pc";
        "qt.fix.broken.gif.crash.diff.gz";
        "qt.mysql.h.diff.gz";
        "qt.webkit-no_Werror.patch.gz";
        "qt5-dont-add-resource-files-to-qmake-libs.patch";
        "qt5-dont-build-host-libs-static.patch";
        "qt5-qmake-implib-dll-a.patch";
        "qt5-qmake-implib-dll-a.patch~";
        "qt5-use-system-zlib-in-host-libs.patch";
        "qt5-workaround-qtbug-29426.patch";
      ]
    in

    let ffmpeg = add ("ffmpeg", None)
      ~dir:"slackbuilds.org/multimedia"
      ~dependencies:[ lame; x264; opus; libtheora; libvorbis; flac (* XXX: used? *) ]
      ~version:"2.2.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    let make = add ("make", None)
      ~dir:"slackware64-current/d"
      ~dependencies:[]
      ~version:"4.0"
      ~build:5
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let json_c = add ("json-c", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"0.12"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let libgpg_error = add ("libgpg-error", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[]
      ~version:"1.13"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    let libgcrypt = add ("libgcrypt", None)
      ~dir:"slackware64-current/n"
      ~dependencies:[ libgpg_error ]
      ~version:"1.6.1"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    let sdl2 = add ("SDL2", None)
      ~dir:"slackbuilds.org/development"
      ~dependencies:[ win_iconv ]
      ~version:"2.0.3"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let openjpeg = add ("openjpeg", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[ lcms; lcms2 ]
      ~version:"2.1.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    let libxslt = add ("libxslt", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ libxml2 ]
      ~version:"1.1.28"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    let libdvdread = add ("libdvdread", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"4.2.0"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.bz2";
      ]
    in

    let zz_config = add ("zz_config", None)
      ~dir:"mingw"
      ~dependencies:[]
      ~version:"1.0.0"
      ~build:3
      ~sources:[
        "win-builds-switch";
      ]
    in

    add ("all", None)
      ~dir:""
      ~dependencies:[
        gcc; binutils; mingw_w64; gdb;
        elementary; gtk_2; ffmpeg;
        libtheora; opus;
        madplay; icu4c; make; gperf; zz_config;
        jansson; libsigc_plus_plus;
        zlib; xz; winpthreads; pkg_config; libarchive;
        wget; dejavu_fonts_ttf;
        openjpeg; sdl2; libgcrypt;
        widl; glib_networking; libxml2; libsoup; djvulibre; a52dec; libmpeg2;
        pcre; libxslt; libdvdread
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]

  in

  let _experimental =
    let libidn = add ("libidn", None)
      (* NOTE: Uses gnulib with MSVC bits licensd as GPLv3; *NOT* LGPL. *)
      (* NOTE: Wget can depend on libidn (wget's license has to be checked). *)
      (* NOTE: Also, the gnulib MSVC bits don't compile; maybe an update would
       * fix them. *)
      ~dir:"slackware64-current/l"
      ~dependencies:[]
      ~version:"1.25"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    (* TODO: check for new version *)
    let libcdio = add ("libcdio", None)
      ~dir:"slackware64-current/l"
      ~dependencies:[ (* libcddb *) ]
      ~version:"0.83"
      ~build:1
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.xz";
      ]
    in

    add ("experimental", None)
      ~dir:""
      ~dependencies:[
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]

    (* 
      let sdl:base = add ("sdl:base", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let sdl:image = add ("sdl:image", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let sdl:mixer = add ("sdl:mixer", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let sdl:net = add ("sdl:net", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let sdl:ttf = add ("sdl:ttf", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let dbus-glib = add ("dbus-glib", None)
        ~dir:"# slackware64-current/l"
        ~dependencies:[]

      let webkitgtk = add ("webkitgtk", None)
        ~dir:"# slackbuilds.org/libraries"
        ~dependencies:[]

      let gucharmap = add ("gucharmap", None)
        ~dir:"slackware64-current/xap"
        ~dependencies:[ gtk_3 ]

      (* includes <pwd.h> *)
      let geeqie = add ("geeqie", None)
        ~dir:"slackware64-current/xap"
        ~dependencies:[]

      let luajit = add ("luajit", None)
        ~dir:"slackbuilds.org/development"
        ~dependencies:[]

      let file = add ("file", None)
        ~dir:"slackware64-current/a"
        ~dependencies:[]

      let cdparanoia = add ("cdparanoia", None)
        ~dir:"slackware64-current/ap"
        ~dependencies:[]

      let fdk_aac = add ("fdk-aac", None)
        ~dir:"mingw"
        ~dependencies:[]
        ~version:"2.34"
        ~build:1
        ~sources:[
          "${PACKAGE}-${VERSION}.tar.xz";
        ]
      in

      let libcddb = add ("libcddb", None)
        ~dir:"slackware64-current/l"
        ~dependencies:[]
    *)

  in

  let _disabled =
    let speex = add ("speex", None)
      ~dir:"slackbuilds.org/audio"
      ~dependencies:[ (* libogg *) ]
      ~version:"1.2rc1"
      ~build:3
      ~sources:[
        "${PACKAGE}-${VERSION}.tar.gz";
      ]
    in

    add ("disabled", None)
      ~dir:""
      ~dependencies:[
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]

  in

  ()

let builder_32 =
  builder ~name:"windows_32" ~host:Config.Arch.windows_32 ~cross:Cross_toolchain.builder_32
let builder_64 =
  builder ~name:"windows_64" ~host:Config.Arch.windows_64 ~cross:Cross_toolchain.builder_64

let () =
  do_adds builder_32;
  do_adds builder_64
