import os
from static_precompiler import exceptions, utils, url_converter
from static_precompiler.compilers import base, less

__all__ = (
  "CoyoteCompiler",
  "ImprovedLESS"
)


class CoyoteCompiler(base.BaseCompiler):
  name = "coyote"
  input_extension = "coffee"
  output_extension = "js"

  def __init__(self, executable="coyote", compress=False):
    self.executable = executable
    self.compress = compress

    super(CoyoteCompiler, self).__init__()

  def should_compile(self, source_path, from_management=False):
    # if settings.DEBUG:
    #   return True

    return super(CoyoteCompiler, self).should_compile(source_path, from_management)

  def compile_file(self, source_path):
    full_output_path = self.get_full_output_path(source_path)
    args = [
      self.executable,
    ]
    if self.compress:
      args.append("-c")

    args.append(
      "{}:{}".format(self.get_full_source_path(source_path), full_output_path)
    )

    return_code, out, errors = utils.run_command(args)

    if return_code:
      raise exceptions.StaticCompilationError(errors)

    print("Hi")
    return self.get_output_path(source_path)

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
