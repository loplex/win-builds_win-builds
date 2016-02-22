function quote(s) {
  gsub("\"", "\\\"", s);
  gsub("\\", "\\\\", s);
  return "\"" s "\"";
}

BEGIN {
  replacements["%{PKG}"] = quote(PKG);
  replacements["%{HST}"] = quote(HOST_TRIPLET);
  replacements["some %{TGT}"] = TARGET_TRIPLET;
  replacements["%{DESCR}"] = quote(DESCRIPTION);
  replacements["%{VER} 0"] = quote(VERSION) " " BUILD;
  replacements["%{PACKAGER}"] = quote(PACKAGER);
  replacements["%{PACKAGER_MAIL}"] = quote(PACKAGER_MAIL);
  replacements["\\(some_predicate some_value\\)"] = PREDICATE_SUB;

  replacement_env_var_prefix = "EXTRA_REPLACEMENT_";

  for (name in ENVIRON) {
    if (name ~ ("^" replacement_env_var_prefix)) {
      val = ENVIRON[name];
      sub(replacement_env_var_prefix, "", name);
      replacements[ "%{" name "}" ] = val;
    }
  }
}

{
  for (search in replacements) {
    sub(search, replacements[search]);
  }

  print $0;
}
