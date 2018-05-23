xquery version "3.1";

import module namespace data = "http://gawati.org/xq/db/data" at "data.xql";
declare namespace an="http://docs.oasis-open.org/legaldocml/ns/akn/3.0";

data:search-filter-timeline("[.//an:FRBRcountry[ @value eq 'mu' or @value eq 'et' or @value eq 'tg' or @value eq 'bj' or @value eq 'mg' or @value eq 'ng']]")

