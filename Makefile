VALAC=valac
VALA_FLAGS=--pkg vte-2.90 --fatal-warnings

taterm:

% : %.vala
	$(VALAC) $(VALA_FLAGS) $^

%.c : %.vala
	$(VALAC) -C $(VALA_FLAGS) $^
