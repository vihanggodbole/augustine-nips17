Change in raw data.
 - The party predicate was removed to better support fully integer identifiers.
 - Bias was fully computed so we don't need a functional predicate.
 - Bias was reworked to not depend on Party. It now is Bias(Person, PartyId).
 - Made inference targets explicit.
 - Added a negative prior on  votes.
