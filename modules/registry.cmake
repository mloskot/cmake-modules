get_filename_component(_windows10_kits_root_dir
  "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows Kits\\Installed Roots;KitsRoot10]"
  ABSOLUTE)
message("X ${_windows10_kits_root_dir}")
file(GLOB _windows10_kits_dirs LIST_DIRECTORIES TRUE "${_windows10_kits_root_dir}")
message("Z ${_windows10_kits_dirs}")