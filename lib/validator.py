import re

from cerberus.validator import Validator
from cerberus.errors import BasicErrorHandler
from django.utils.translation import gettext_lazy as _


class HumanReadableValidationError(BasicErrorHandler):
  messages = {0x00: "{0}",

              0x01: _("document is missing"),
              0x02: _("required field"),
              0x03: _("unknown field"),
              0x04: _("field '{0}' is required"),
              0x05: _("depends on these values: {constraint}"),
              0x06: _("{0} must not be present with '{field}'"),

              0x21: _("'{0}' is not a document, must be a dict"),
              0x22: _("empty values not allowed"),
              0x23: _("value needs to be supplied"),
              0x24: _("must be of {constraint} type"),
              0x25: _("must be of dict type"),
              0x26: _("length of list should be {constraint}, it is {0}"),
              0x27: _("min length is {constraint}"),
              0x28: _("max length is {constraint}"),

              0x41: _("value does not match regex '{constraint}'"),
              0x42: _("min value is {constraint}"),
              0x43: _("max value is {constraint}"),
              0x44: _("unallowed value {value}"),
              0x45: _("unallowed values {0}"),
              0x46: _("unallowed value {value}"),
              0x47: _("unallowed values {0}"),

              0x61: _("field '{field}' cannot be coerced: {0}"),
              0x62: _("field '{field}' cannot be renamed: {0}"),
              0x63: _("field is read-only"),
              0x64: _("default value for '{field}' cannot be set: {0}"),

              0x81: _("mapping doesn't validate subschema: {0}"),
              0x82: _("one or more sequence-items don't validate: {0}"),
              0x83: _("one or more keys of a mapping  don't validate: {0}"),
              0x84: _("one or more values in a mapping don't validate: {0}"),
              0x85: _("one or more sequence-items don't validate: {0}"),

              0x91: _("one or more definitions validate"),
              0x92: _("none or more than one rule validate"),
              0x93: _("no definitions validate"),
              0x94: _("one or more definitions don't validate")
              }


class BaseValidator(Validator):
  def __init__(self, *args, **kwargs):
    kwargs['error_handler'] = HumanReadableValidationError()
    super().__init__(*args, **kwargs)

  def _validate_type_uuid(self, value):
    re_uuid = re.compile(r'[0-9a-f]{8}(?:(?:-)?[0-9a-f]{4}){3}(?:-)?[0-9a-f]{12}', re.I)
    if re_uuid.match(value):
      return True

  def _validate_type_steamid(self, value):
    val = value
    if isinstance(val, str) and value.isdigit():
      val = int(val)

    if isinstance(val, int) and 76561197960265729 <= value < 76561202255233023:
      return True

    return False

  def _validate_type_ip(self, value):
    re_ip = re.compile(
        r'(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])',
        re.I)
    if re_ip.match(value):
      return True

  def _validate_type_email(self, value):
    re_email = re.compile(r'(^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$)')

    if re_email.match(value):
      return True
