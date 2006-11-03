# Copyright: 2005 Brian Harring <ferringb@gmail.com>
# License: GPL2

"""
simple repository wrapping to override the package instances returned
"""

# icky.
# ~harring
from pkgcore.repository import prototype, errors
from pkgcore.util.klass import GetAttrProxy

class tree(prototype.tree):

    """wrap an existing repository yielding wrapped packages."""

    def __init__(self, repo, package_class=None):
        """
        @param repo: L{pkgcore.repository.prototype.tree} instance to wrap
        @param package_class: callable to yield the package instance
        """
        self.raw_repo = repo
        if not isinstance(self.raw_repo, prototype.tree):
            raise errors.InitializationError(
                "%s is not a repository tree derivative" % (self.raw_repo,))
        self.package_class = package_class
        self.raw_repo = repo

    def itermatch(self, *args, **kwargs):
        if self.package_class is None:
            return self.raw_repo.itermatch(*args, **kwargs)
        return (
            self.package_class(x)
            for x in self.raw_repo.itermatch(*args, **kwargs))

    __getattr__ = GetAttrProxy("raw_repo")

    def __len__(self):
        return len(self.raw_repo)

    def __iter__(self):
        if self.package_class is None:
            return iter(self.raw_repo)
        return (self.package_class(x) for x in self.raw_repo)
