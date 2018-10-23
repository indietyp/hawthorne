import os
import posixpath
import re

from static_precompiler import exceptions, url_converter, utils
from static_precompiler.compilers import base, less

__all__ = (
    "CoyoteCompiler",
    "ImprovedLESS"
)


class CoyoteCompiler(base.BaseCompiler):
  name = "coyote"
  input_extension = "coffee"
  output_extension = "js"

  supports_dependencies = True

  REQUIRE_RE = r'#=\srequire\s(.+)'

  def __init__(self, executable="coyote", compress=False):
    self.executable = executable
    self.compress = compress

    super(CoyoteCompiler, self).__init__()

  def compile_file(self, source_path):
    full_output_path = self.get_full_output_path(source_path)
    args = [self.executable]

    args.append(
        "{}:{}".format(self.get_full_source_path(source_path), full_output_path)
    )

    return_code, out, errors = utils.run_command(args)

    if return_code:
      raise exceptions.StaticCompilationError(errors)

    if self.compress:
      args = ['google-closure-compiler',
              '--compilation_level=SIMPLE',
              '--js=' + full_output_path,
              '--create_source_map=' + full_output_path + '.map',
              '--assume_function_wrapper']

      return_code, out, errors = utils.run_command(args)

      with open(full_output_path, 'w') as file:
        file.write(out)

    return self.get_output_path(source_path)

  def locate_imported_file(self, source_dir, import_path):
    return posixpath.normpath(posixpath.join(source_dir, import_path))

  def find_requirements(self, source):
    imports = re.findall(self.REQUIRE_RE, source)

    return imports

  def find_dependencies(self, source_path):
    source = self.get_source(source_path)
    source_dir = posixpath.dirname(source_path)
    dependencies = set()
    for import_path in self.find_requirements(source):
      import_path = self.locate_imported_file(source_dir, import_path)
      dependencies.add(import_path)
      dependencies.update(self.find_dependencies(import_path))
    return sorted(dependencies)

  def compile_source(self, source):
    raise exceptions.StaticCompilationError("This is currently not supported")


class ImprovedLESS(less.LESS):
  def compile_file(self, source_path):
    full_source_path = self.get_full_source_path(source_path)
    full_output_path = self.get_full_output_path(source_path)

    # `cwd` is a directory containing `source_path`.
    # Ex: source_path = '1/2/3', full_source_path = '/abc/1/2/3' -> cwd = '/abc'
    cwd = os.path.normpath(os.path.join(full_source_path, *([".."] * len(source_path.split("/")))))

    args = [
        self.executable
    ]
    if self.is_sourcemap_enabled:
        args.extend([
            "--source-map"
        ])
    if self.include_path:
        args.extend([
            "--include-path={}".format(self.include_path)
        ])
    if self.clean_css:
        args.extend([
            "--clean-css",
        ])
    if self.global_vars:
        for variable_name, variable_value in self.global_vars.items():
            args.extend([
                "--global-var={0}={1}".format(variable_name, variable_value),
            ])

    args.extend([
        self.get_full_source_path(source_path),
    ])
    return_code, out, errors = utils.run_command(args, cwd=cwd)

    with open(full_output_path, "w") as inp:
      inp.write(out)

    if return_code:
        raise exceptions.StaticCompilationError(errors)

    url_converter.convert_urls(full_output_path, source_path)

    if self.is_sourcemap_enabled:
        utils.fix_sourcemap(full_output_path + ".map", source_path, full_output_path)

    return self.get_output_path(source_path)
