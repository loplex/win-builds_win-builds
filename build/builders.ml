open Lib

module Native_toolchain = struct
  let builder =
    let open Config in
    let name = "native_toolchain" in
    let prefix = Arch.(Prefix.t ~name ~build ~host:build ~target:build) in
    let logs, yyoutput = Package.logs_yyoutput ~nickname:prefix.Prefix.nickname in
    let open Arch in
    let open Prefix in
    let open Package in
    let open Builder in
    {
      name;
      prefix; logs; yyoutput;
      path = Env.Prepend [ prefix.yyprefix ^/ "bin" ];
      pkg_config_path = Env.Prepend [ prefix.libdir ^/ "pkgconfig" ];
      pkg_config_libdir = Env.Keep;
      tmp = Env.Set [ prefix.yyprefix ^/ "tmp" ];
      target_prefix = None;
      cross_prefix  = None;
      native_prefix = None;
      cross_name = None;
      packages = [];
      redistributed = false;
      default_cross_deps = [];
      ld_library_path = Env.Prepend [ prefix.libdir ];
      c_path = Env.Prepend [ prefix.yyprefix ^/ "include" ];
      library_path = Env.Prepend [ prefix.libdir ];
    }
end

module Cross_toolchain = struct
  let make ~name ~target =
    let open Config in
    let prefix = Prefix.t ~name ~build:Arch.build ~host:Arch.build ~target in
    let logs, yyoutput = Package.logs_yyoutput ~nickname:prefix.Prefix.nickname in
    let open Arch in
    let open Prefix in
    let open Package in
    let open Builder in
    let native_prefix = Native_toolchain.builder.prefix in
    {
      name;
      prefix; logs; yyoutput;
      path = Env.Prepend [
        prefix.yyprefix ^/ "bin";
        native_prefix.yyprefix ^/ "bin"
      ];
      (* FIXME: this should also include native_prefix *)
      pkg_config_path = Env.Prepend [ prefix.libdir ^/ "pkgconfig" ];
      pkg_config_libdir = Env.Keep;
      tmp = Env.Set [ prefix.yyprefix ^/ "tmp" ];
      target_prefix = None; (* updated from the Windows module *)
      cross_prefix  = None;
      native_prefix = Some native_prefix.yyprefix;
      cross_name = None;
      packages = [];
      redistributed = false;
      default_cross_deps = [];
      ld_library_path = Env.Prepend [ prefix.libdir; native_prefix.libdir ];
      c_path = Env.Prepend [
        prefix.yyprefix ^/ "include";
        native_prefix.yyprefix ^/ "include";
      ];
      library_path = Env.Prepend [
        prefix.libdir;
        native_prefix.libdir;
      ];
    }

  let builder_32 =
      make ~name:"cross_toolchain_32" ~target:Config.Arch.windows_32
  let builder_64 =
      make ~name:"cross_toolchain_64" ~target:Config.Arch.windows_64
end

module Windows = struct
  let make ~cross ~name ~host =
    let open Config in
    let prefix = Prefix.t ~name ~build:Arch.build ~host ~target:host in
    let logs, yyoutput = Package.logs_yyoutput ~nickname:prefix.Prefix.nickname in
    cross.Config.Builder.target_prefix <- Some prefix.Prefix.yyprefix;
    let open Arch in
    let open Prefix in
    let open Package in
    let open Builder in
    let native_prefix = Native_toolchain.builder.prefix in
    {
      name;
      prefix; logs; yyoutput;
      path = Env.Prepend [
        cross.prefix.yyprefix ^/ "bin";
        native_prefix.yyprefix ^/ "bin"
      ];
      pkg_config_path = Env.Clear;
      pkg_config_libdir = Env.Set [ prefix.libdir ^/ "pkgconfig" ] ;
      tmp = Env.Set [ prefix.Prefix.yyprefix ^/ "tmp" ];
      target_prefix = None;
      cross_prefix  = Some cross.Config.Builder.prefix.Prefix.yyprefix;
      native_prefix = Some native_prefix.Prefix.yyprefix;
      cross_name = Some cross.name;
      packages = [];
      redistributed = false;
      default_cross_deps = [ "gcc:full" ];
      ld_library_path = Env.Prepend [
        cross.prefix.libdir;
        native_prefix.libdir;
      ];
      c_path = Env.Clear;
      library_path = Env.Clear;
    }

  (* builder_ministat needs to come before builder_32 because one will shadow
   * the other's ${yyprefix_target} and we don't want it the other way round. *)
  let builder_ministat =
    make ~name:"windows_ministat" ~host:Config.Arch.windows_32 ~cross:Cross_toolchain.builder_32

  let builder_32 = 
    make ~name:"windows_32" ~host:Config.Arch.windows_32 ~cross:Cross_toolchain.builder_32

  let builder_64 =
    make ~name:"windows_64" ~host:Config.Arch.windows_64 ~cross:Cross_toolchain.builder_64

end
