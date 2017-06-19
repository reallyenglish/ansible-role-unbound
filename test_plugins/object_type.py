from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible import errors

def isdict(x):
    return bool(isinstance(x, dict))

def islist(x):
    return bool(isinstance(x, list))

class TestModule(object):
    ''' Ansible file jinja2 tests to test object types'''

    def tests(self):
        return {
            'isdict' : isdict,
            'islist' : islist,
        }
