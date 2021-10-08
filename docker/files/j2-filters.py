# NOTE: These are taken from the jinja2-ansible-filters package:
# NOTE: https://pypi.org/project/jinja2-ansible-filters
# NOTE: The installer has a problem in its egg-info preventing a regular pip install.
# NOTE: If we do not need the b64encode filter, we can omit this file and the filter setup.

# (c) 2012, Jeroen Hoekx <jeroen@hoekx.be>
#
# This file was ported from Ansible
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# Make coding more python3-ish
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

import base64
import codecs

try:
    string_types = basestring,
    integer_types = (int, long)
    class_types = (type, types.ClassType)
    text_type = unicode
    binary_type = str
    from collections import Sequence
except NameError:
    # Python3.x environment
    string_types = str
    integer_types = int
    class_types = type
    text_type = str
    binary_type = bytes

try:
    codecs.lookup_error("surrogateescape")
    HAS_SURROGATEESCAPE = True
except LookupError:
    HAS_SURROGATEESCAPE = False

_COMPOSED_ERROR_HANDLERS = frozenset((None, "surrogate_or_replace",
                                      "surrogate_or_strict",
                                      "surrogate_then_replace"))


def to_bytes(obj, encoding="utf-8", errors=None, nonstring="simplerepr"):
    if isinstance(obj, binary_type):
        return obj

    # We're given a text string
    # If it has surrogates, we know because it will decode
    original_errors = errors
    if errors in _COMPOSED_ERROR_HANDLERS:
        if HAS_SURROGATEESCAPE:
            errors = "surrogateescape"
        elif errors == "surrogate_or_strict":
            errors = "strict"
        else:
            errors = "replace"

    if isinstance(obj, text_type):
        try:
            # Try this first as it's the fastest
            return obj.encode(encoding, errors)
        except UnicodeEncodeError:
            if original_errors in (None, "surrogate_then_replace"):

                # Slow but works
                return_string = obj.encode("utf-8", "surrogateescape")
                return_string = return_string.decode("utf-8", "replace")
                return return_string.encode(encoding, "replace")
            raise

    # Note: We do these last even though we have to call to_bytes again on the
    # value because we're optimizing the common case
    if nonstring == "simplerepr":
        try:
            value = str(obj)
        except UnicodeError:
            try:
                value = repr(obj)
            except UnicodeError:
                # Giving up
                return to_bytes("")
    elif nonstring == "passthru":
        return obj
    elif nonstring == "empty":
        # python2.4 doesn't have b''
        return to_bytes("")
    elif nonstring == "strict":
        raise TypeError("obj must be a string type")
    else:
        raise TypeError(
            "Invalid value %s for to_bytes' nonstring parameter" % nonstring)

    return to_bytes(value, encoding, errors)


def to_text(obj, encoding="utf-8", errors=None, nonstring="simplerepr"):
    if isinstance(obj, text_type):
        return obj

    if errors in _COMPOSED_ERROR_HANDLERS:
        if HAS_SURROGATEESCAPE:
            errors = "surrogateescape"
        elif errors == "surrogate_or_strict":
            errors = "strict"
        else:
            errors = "replace"

    if isinstance(obj, binary_type):
        # Note: We don't need special handling for surrogate_then_replace
        # because all bytes will either be made into surrogates or are valid
        # to decode.
        return obj.decode(encoding, errors)

    # Note: We do these last even though we have to call to_text again on the
    # value because we're optimizing the common case
    if nonstring == "simplerepr":
        try:
            value = str(obj)
        except UnicodeError:
            try:
                value = repr(obj)
            except UnicodeError:
                # Giving up
                return u""
    elif nonstring == "passthru":
        return obj
    elif nonstring == "empty":
        return u""
    elif nonstring == "strict":
        raise TypeError("obj must be a string type")
    else:
        raise TypeError(
            "Invalid value %s for to_text's nonstring parameter" % nonstring)

    return to_text(value, encoding, errors)


def b64encode(string, encoding="utf-8"):
    return to_text(base64.b64encode(to_bytes(string,
                                             encoding=encoding,
                                             errors="surrogate_or_strict")))


class FilterModule(object):
    """ Ansible core jinja2 filters """

    def filters(self):
        return {
            # base 64
            "b64encode": b64encode,
        }
