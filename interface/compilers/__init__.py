from static_precompiler.compilers import base
from static_precompiler import exceptions, utils
from django.conf import settings

__all__ = (
    "CoyoteCompiler",
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
