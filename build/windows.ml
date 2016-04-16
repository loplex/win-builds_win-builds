let do_adds builder =
  let open Sources in
  let add = Worker.register ~builder in

  let _all =

#use "slackware/d/autoconf/wb.ml"
#use "slackware/d/libtool/wb.ml"
#use "slackware/d/automake/wb.ml"
  let mingw_w64_deps = [] in
#use "slackbuilds.org/win-builds/mingw-w64/wb-common.ml"
#use "slackbuilds.org/win-builds/mingw-w64/wb-full.ml"
#use "slackbuilds.org/win-builds/gendef/wb.ml"
#use "slackbuilds.org/win-builds/genidl/wb.ml"
#use "slackbuilds.org/win-builds/genpeimg/wb.ml"
#use "slackbuilds.org/win-builds/libmangle/wb.ml"
#use "slackbuilds.org/win-builds/winstorecompat/wb.ml"
#use "slackbuilds.org/win-builds/widl/wb.ml"
#use "slackbuilds.org/win-builds/win-iconv/wb.ml"
#use "slackbuilds.org/win-builds/musl-private/wb.ml"
ignore musl_private; (* file was only included to get musl's version *)
#use "slackbuilds.org/win-builds/tre/wb.ml"
#use "slackware/a/gettext/wb.ml"
    let gettext = add (gettext_name, gettext_variant)
      ~dir:gettext_dir
      ~dependencies:[ win_iconv ]
      ~version:gettext_version
      ~build:gettext_build
      ~sources:gettext_sources
    in

#use "slackware/a/xz/wb-common.ml"
    let xz = xz_add ~variant:"regular" ~dependencies:[ gettext ] in

#use "slackware/l/zlib/wb-regular.ml"
#use "slackware/l/libjpeg-turbo/wb.ml"
#use "slackware/l/expat/wb-regular.ml"
#use "slackware/l/libpng/wb.ml"
#use "slackware/l/freetype/wb.ml"
#use "slackware/x/fontconfig/wb-common.ml"
    let fontconfig = fontconfig_add ~variant:"regular" ~dependencies:[ freetype; expat ] in

#use "slackware/l/giflib/wb.ml"
#use "slackware/l/libtiff/wb-common.ml"
    let libtiff = libtiff_add ~variant:"regular" ~dependencies:[ libjpeg_turbo; xz ] in
#use "slackbuilds.org/development/lua/wb-regular.ml"
#use "slackbuilds.org/development/luajit/wb.ml"
    let luajit = luajit_add ~dependencies:[] in
#use "slackware/n/ca-certificates/wb.ml"
#use "slackware/n/openssl/wb.ml"
#use "slackware/l/gmp/wb.ml"
#use "slackware/n/nettle/wb.ml"
#use "slackware/l/libtasn1/wb.ml"
#use "slackware/n/gnutls/wb.ml"
#use "slackware/n/curl/wb-regular.ml"
#use "slackbuilds.org/libraries/c-ares/wb.ml"
#use "slackbuilds.org/win-builds/pixman/wb.ml"
#use "slackware/a/bzip2/wb.ml"
#use "slackware/l/pcre/wb.ml"
#use "slackware/l/libffi/wb.ml"
#use "slackware/l/glib2/wb.ml"
#use "slackware/d/pkg-config/wb-common.ml"
#use "slackware/d/pkg-config/wb.ml"
#use "slackware/l/cairo/wb.ml"
#use "slackware/l/atk/wb.ml"
#use "slackware/l/icu4c/wb.ml"
#use "slackware/l/harfbuzz/wb.ml"
#use "slackware/l/pango/wb.ml"
#use "slackware/l/gdk-pixbuf2/wb.ml"
#use "slackware/l/gtk+2/wb.ml"
#use "slackware/x/libepoxy/wb.ml"
#use "slackware/l/gtk+3/wb.ml"
#use "slackware/l/adwaita-icon-theme/wb.ml"
#use "slackware/xap/gucharmap/wb.ml"
#use "slackware/l/glib-networking/wb.ml"
#use "slackware/l/libxml2/wb.ml"
#use "slackware/l/libcroco/wb.ml"

    let gettext_tools = add ("gettext-tools", None)
      ~dir:"slackware/d"
      (* check that it indeed depends on gettext *)
      ~dependencies:[ libcroco; gettext; glib2; libxml2; expat; (* unistring; libpth *) ]
      ~version:gettext_version
      ~build:gettext_build
      ~sources:gettext_sources
    in

#use "slackware/ap/sqlite/wb.ml"
#use "slackware/l/libsoup/wb.ml"
#use "slackware/d/gperf/wb.ml"
#use "slackware/d/bison/wb.ml"
#use "slackware/l/mpfr/wb.ml"
#use "slackware/l/libmpc/wb.ml"
#use "slackware/l/libogg/wb.ml"
#use "slackware/l/libvorbis/wb.ml"
#use "slackware/l/libtheora/wb.ml"
#use "slackware/l/fribidi/wb.ml"
#use "slackbuilds.org/development/check/wb.ml"
#use "slackware/a/dbus/wb-common.ml"
    let dbus = dbus_add ~variant:"regular" ~dependencies:[ expat ] in

#use "slackware/l/libarchive/wb-common.ml"
    let libarchive = libarchive_add ~variant:"regular" ~dependencies:[ nettle; tre; libxml2 ] in

#use "slackware/n/wget/wb.ml"
    let binutils_dependencies = [ zlib ] in
#use "slackware/d/binutils/wb.ml"
    let gcc_core_dependencies = [] in
    let gcc_native_dependencies = [] in
#use "slackware/d/gcc/wb-core.ml"
ignore gcc_core; (* wb-core.ml is only used to get the version *)
    let gcc_full_dependencies = [ mpfr; gmp; libmpc; mingw_w64_full ] in
#use "slackware/d/gcc/wb-full.ml"

#use "slackbuilds.org/multimedia/x264/wb.ml"
#use "slackware/l/libao/wb.ml"
#use "slackware/ap/flac/wb.ml"
#use "slackware/l/lcms/wb.ml"
#use "slackware/l/lcms2/wb.ml"
#use "slackbuilds.org/libraries/bullet/wb.ml"
#use "slackware/l/openjpeg/wb.ml"
#use "slackware/l/libsndfile/wb.ml"
#use "slackware/l/orc/wb.ml"
#use "slackware/l/gstreamer/wb.ml"
#use "slackware/l/gst-plugins-base/wb.ml"
#use "slackware/l/gst-plugins-good/wb.ml"
#use "slackware/n/libgpg-error/wb.ml"
#use "slackware/n/libgcrypt/wb.ml"
#use "slackbuilds.org/libraries/efl/wb-common.ml"
#use "slackbuilds.org/libraries/efl/wb-regular.ml"
#use "slackbuilds.org/libraries/elementary/wb-regular.ml"
#use "slackware/d/gdb/wb.ml"
#use "slackware/l/libmad/wb.ml"
#use "slackware/l/libid3tag/wb.ml"
#use "slackware/ap/madplay/wb.ml"
#use "slackware/l/djvulibre/wb.ml"
#use "slackware/x/dejavu-fonts-ttf/wb.ml"
#use "slackbuilds.org/audio/opus/wb.ml"
#use "slackware/l/a52dec/wb.ml"
#use "slackbuilds.org/libraries/libmpeg2/wb.ml"
#use "slackware/l/libsigc++/wb.ml"
#use "slackbuilds.org/libraries/jansson/wb.ml"
#use "slackbuilds.org/libraries/lame/wb.ml"

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

#use "slackware/l/speexdsp/wb.ml"
#use "slackbuilds.org/audio/speex/wb.ml"
#use "slackbuilds.org/multimedia/ffmpeg/wb.ml"
#use "slackware/d/make/wb.ml"
#use "slackware/l/json-c/wb.ml"
#use "slackbuilds.org/libraries/SDL2/wb.ml"
#use "slackware/l/libxslt/wb.ml"
#use "slackware/l/libdvdread/wb.ml"
#use "slackware/l/libdvdnav/wb.ml"
#use "slackbuilds.org/libraries/libdvdcss/wb.ml"
#use "slackware/ap/sox/wb.ml"
#use "slackware/l/babl/wb.ml"
#use "slackware/l/gegl/wb.ml"
#use "slackware/xap/gimp/wb.ml"
#use "slackbuilds.org/multimedia/vlc/wb.ml"
#use "slackware/l/db48/wb.ml"
#use "slackware/l/ncurses/wb.ml"
#use "slackware/l/readline/wb.ml"
#use "slackware/a/file/wb.ml"
    let file = file_add ~dependencies:[ tre ] in
#use "slackbuilds.org/win-builds/rufus/wb.ml"
#use "slackbuilds.org/win-builds/examine/wb.ml"
    let examine = examine_add ~dependencies:[ binutils; gcc_full ] in
#use "slackware/d/python/wb.ml"
#use "slackware/l/boost/wb.ml"
#use "slackbuilds.org/win-builds/zz_config/wb.ml"

#extras

    add ("all", None)
      ~dir:""
      ~dependencies:[
        autoconf; automake; libtool; gettext_tools;
        gcc_full; binutils; mingw_w64_full; gdb;
        elementary; gtk_2; gtk_3; gucharmap; ffmpeg;
        libtheora; opus; sox;
        madplay; icu4c; make; gperf; zz_config;
        jansson; libsigc_plus_plus;
        zlib; xz; pkg_config; libarchive;
        wget; dejavu_fonts_ttf;
        libjpeg_turbo; openjpeg; sdl2; libgcrypt;
        glib_networking; libxml2; libsoup; djvulibre; a52dec; libmpeg2;
        pcre; libxslt; libdvdread; libdvdnav; libdvdcss;
        gendef; genidl; genpeimg; widl; libmangle; winstorecompat;
        babl; gegl; gimp; gstreamer1; gst1_plugins_good; bullet;
        json_c;
        check; bison; python; boost; vlc; tre; (* adwaita_icon_theme; *)
        readline; ncurses; luajit;
        rufus; examine;
        openssl; file;
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]
      ~outputs:[]

  in

  let _experimental =
    let _libidn = add ("libidn", None)
      (* NOTE: Uses gnulib with MSVC bits licensd as GPLv3; *NOT* LGPL. *)
      (* NOTE: Wget can depend on libidn (wget's license has to be checked). *)
      (* NOTE: Also, the gnulib MSVC bits don't compile; maybe an update would
       *       fix them. *)
      ~dir:"slackware/l"
      ~dependencies:[]
      ~version:"1.25"
      ~build:1
      ~sources:[
        Tarball ("${PACKAGE}-${VERSION}.tar.xz", "e1b18e18b0eca1852baff7ca55acce42096479da");
      ]
    in

    (* NOTE: dependency on regex *)
    (* NOTE: has an enum field "SEARCH_ALL" which conflicts with a #define from
     *       Windows and is public API. *)
    let _libcddb = add ("libcddb", None)
      ~dir:"slackware/l"
      ~dependencies:[]
      ~version:"1.3.2"
      ~build:1
      ~sources:[
        Tarball ("${PACKAGE}-${VERSION}.tar.xz", "1869ff09b522b9857f242ab4b06c5e115f46ff14");
      ]
    in

    let _libcdio = add ("libcdio", None)
      ~dir:"slackware/l"
      ~dependencies:[ _libcddb ]
      ~version:"0.83"
      ~build:1
      ~sources:[
        Tarball ("${PACKAGE}-${VERSION}.tar.xz", "dc03799b2ab878def5e0517d70f65a91538e9bc1");
      ]
    in

    let _miniupnpc = add ("miniupnpc", None)
      ~dir:"slackbuilds.org/libraries"
      ~dependencies:[]
      ~version:"1.9"
      ~build:1
      ~sources:[
        Tarball ("${PACKAGE}-${VERSION}.tar.gz", "643001d52e322c52a7c9fdc8f31a7920f4619fc0");
      ]
    in

    add ("experimental", None)
      ~dir:""
      ~dependencies:[
      ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]
      ~outputs:[]

    (* 
      let sdl:base = add ("sdl:base", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let sdl:image = add ("sdl:image", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let sdl:mixer = add ("sdl:mixer", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let sdl:net = add ("sdl:net", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let sdl:ttf = add ("sdl:ttf", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let dbus-glib = add ("dbus-glib", None)
        ~dir:"# slackware/l"
        ~dependencies:[]

      let webkitgtk = add ("webkitgtk", None)
        ~dir:"# slackbuilds.org/libraries"
        ~dependencies:[]

      (* includes <pwd.h> *)
      let geeqie = add ("geeqie", None)
        ~dir:"slackware/xap"
        ~dependencies:[]

      let cdparanoia = add ("cdparanoia", None)
        ~dir:"slackware/ap"
        ~dependencies:[ libcdio? ]

      let fdk_aac = add ("fdk-aac", None)
        ~dir:"mingw"
        ~dependencies:[]
        ~version:"2.34"
        ~build:1
        ~sources:[
          "${PACKAGE}-${VERSION}.tar.xz";
        ]
      in

    *)

  in

  let _download =
    (* fake package to reserve the name and make it known to the builder *)
    add ("download", None)
      ~dir:""
      ~dependencies:[]
      ~cross_deps:[ "all" ]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]
      ~outputs:[]
  in

  let _disabled =
    let _vpnc = add ("vpnc", None)
      ~dir:"slackbuilds.org/network"
      ~dependencies:[ (* libogg *) ]
      ~version:"0.5.3"
      ~build:1
      ~sources:[
        Tarball ("${PACKAGE}-${VERSION}.tar.gz", "321527194e937371c83b5e7c38e46fca4f109304");
      ]
    in

    add ("disabled", None)
      ~dir:""
      ~dependencies:[]
      ~version:"0.0.0"
      ~build:1
      ~sources:[]
      ~outputs:[]

  in

  ()

let do_adds_ministat () =
  let open Sources in
  let builder = Builders.Windows.builder_ministat in
  let add = Worker.register ~builder in

#use "slackbuilds.org/ocaml/ocaml-findlib/wb.ml"
  let ocaml_findlib = ocaml_findlib_add
    ~dependencies:[]
    ~native_deps:[]
    ~cross_deps:[ "ocaml-findlib" ]
  in

  let ocaml_cryptokit = add ("ocaml-cryptokit", None)
    ~dir:"slackbuilds.org/ocaml"
    ~dependencies:[ ocaml_findlib ]
    ~cross_deps:[ "ocaml" ]
    ~version:"1.10"
    ~build:1
    ~sources:[
      Tarball ("cryptokit-${VERSION}.tar.gz", "73d9c450fd9f3c38089381673fdda6c8b46740b6");
    ]
  in

  let ocaml_fileutils = add ("ocaml-fileutils", None)
    ~dir:"slackbuilds.org/ocaml"
    ~dependencies:[ ocaml_findlib ]
    ~cross_deps:[ "ocaml" ]
    ~version:"0.4.5"
    ~build:1
    ~sources:[
      Tarball ("${PACKAGE}-${VERSION}.tar.gz", "94d02385a55eef373eb96f256068d3efa724016b");
      Patch "0001-FileUtil-replace-stat.is_link-boolean-with-a-Link-va.patch";
      Patch "0002-FileUtil-symlinks-patch-2.patch";
    ]
  in

  let libocaml_http =
    let libocaml_add subpackage ~dependencies ~sha1 =
      add ("libocaml_" ^ subpackage, None)
        ~dir:"slackbuilds.org/ocaml"
        ~dependencies:(ocaml_findlib :: dependencies)
        ~cross_deps:[ "ocaml" ]
        ~version:"v2014-08-08"
        ~build:1
        ~sources:[ Tarball ("${PACKAGE}.${VERSION}.tar.xz", sha1) ]
    in

    let exception_ = libocaml_add "exception"
      ~dependencies:[]
      ~sha1:"69c73123a46f9bc3f3b9a6ec13074d7009d8829b"
    in

    let option_ = libocaml_add "option"
      ~dependencies:[]
      ~sha1:"06401a24a9fc86a796c5ca9dd24a38c7d761cfea"
    in

    let lexing = libocaml_add "lexing"
      ~dependencies:[ exception_ ]
      ~sha1:"3d8ad03b73f423f2dc35e8fc8d77eb662b99c7e7"
    in

    let plus = libocaml_add "plus"
      ~dependencies:[ exception_ ]
      ~sha1:"ee63b54f3be5e855c4b7995dd29e384b09ce5ff6"
    in

    let ipv4_address = libocaml_add "ipv4_address"
      ~dependencies:[ exception_; option_ ]
      ~sha1:"2cf54d0e9e77b9ed61ecd2ad3c9cfe4a50c79513"
    in

    let ipv6_address = libocaml_add "ipv6_address"
      ~dependencies:[ exception_; lexing ]
      ~sha1:"12498c816ce3e10bd945f9d6dd4eff01c2400df7"
    in

    let uri = libocaml_add "uri"
      ~dependencies:[
         exception_; ipv4_address; ipv6_address; lexing; option_; plus
       ]
      ~sha1:"7335da49acfdd61f262bd41e417e422f7ee2e9c2"
    in

    libocaml_add "http"
      ~dependencies:[ lexing; option_; plus; uri ]
      ~sha1:"79a164edaa5421e987883a87a4643a86cac8c971"
  in

#use "slackbuilds.org/win-builds/musl-private/wb.ml"
ignore musl_private; (* file was only included to get musl's version *)
#use "slackbuilds.org/win-builds/tre/wb.ml"
#use "slackware/l/expat/wb-regular.ml"
#use "slackware/a/dbus/wb-common.ml"
  let dbus = dbus_add ~variant:"yypkg" ~dependencies:[ expat ] in

#use "slackware/a/xz/wb-common.ml"
  let xz = xz_add ~variant:"yypkg" ~dependencies:[] in

#use "slackware/l/libarchive/wb-common.ml"
  let libarchive = libarchive_add ~variant:"yypkg" ~dependencies:[ xz ] in

#use "slackware/l/zlib/wb-regular.ml"
#use "slackware/l/libpng/wb.ml"
#use "slackware/l/freetype/wb.ml"
#use "slackware/n/ca-certificates/wb.ml"
#use "slackbuilds.org/win-builds/win-iconv/wb.ml"
#use "slackware/n/curl/wb-yypkg.ml"
#use "slackbuilds.org/libraries/c-ares/wb.ml"
#use "slackbuilds.org/development/lua/wb-regular.ml"
#use "slackware/l/libjpeg-turbo/wb.ml"
#use "slackware/x/fontconfig/wb-common.ml"
    let fontconfig = fontconfig_add ~variant:"yypkg" ~dependencies:[ freetype ] in
#use "slackbuilds.org/libraries/efl/wb-common.ml"
#use "slackbuilds.org/libraries/efl/wb-yypkg.ml"
#use "slackbuilds.org/libraries/elementary/wb-yypkg.ml"

#use "slackbuilds.org/ocaml/ocaml-efl/wb.ml"

  let ocaml_archive = add ("ocaml-archive", None)
    ~dir:"slackbuilds.org/ocaml"
    ~dependencies:[ libarchive; ocaml_findlib; ocaml_fileutils ]
    ~cross_deps:[ "ocaml" ]
    ~version:"2.8.4+2"
    ~build:1
    ~sources:[
      Tarball ("${PACKAGE}-${VERSION}.tar.gz", "4705e7eca920f6d831f2b8020d648d7caa18bb04");
      Patch "0001-_oasis-make-it-possible-to-not-build-tests-docs-and-.patch";
      Patch "0002-Bind-extract-set_pathname-and-read_open_memory-strin.patch";
      Patch "0003-stubs-bind-archive_entry_-set_-pathname-through-a-ma.patch";
      Patch "0004-Bind-archive_entry_-set_-hard-sym-link-and-archive_e.patch";
    ]
  in

  let yypkg = add ("yypkg", None)
    ~dir:"slackbuilds.org/ocaml"
    ~dependencies:[ ocaml_findlib; ocaml_cryptokit;
        ocaml_fileutils; ocaml_archive; ocaml_efl; libocaml_http;
        dbus; libarchive
    ]
    ~cross_deps:[ "ocaml" ]
    ~version:"1.10-alpha2"
    ~build:1
    ~sources:[
      Tarball ("${PACKAGE}-${VERSION}.tar.gz", "51254a1796b282fbe99b145725586921f743a5b7");
    ]
  in

#use "slackware/x/dejavu-fonts-ttf/wb.ml"
#use "slackbuilds.org/win-builds/win-builds-installer/wb.ml"
  ignore win_builds_installer


let () =
  List.iter do_adds Builders.Windows.[ builder_32; builder_64 ];
  ignore (do_adds_ministat ())
