## Makefile.am -- Config file for GNU Automake.
##
## Copyright (C) 2021 Artyom V. Poptsov <poptsov.artyom@gmail.com>
##
## This file is part of Guile-GitLab.
##
## Guile-GitLab is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Guile-GitLab is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Guile-GitLab.  If not, see <http://www.gnu.org/licenses/>.

bin_SCRIPTS = \
	gitlab-cli

EXTRA_DIST = \
	gitlab-cli.in

SUFFIXES = .in

substitute = sed -e 's,[@]GUILE[@],$(GUILE),g'

.in:
	$(substitute) "$^" > "$@.tmp" && 	\
	chmod +x "$@.tmp" &&			\
	mv "$@.tmp" "$@"

CLEANFILES = \
	gitlab-cli

### Makefile.am ends here.
