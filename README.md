# Gawata-Data

This the document repository for Gawati. 

It provides services to access the data to other applications, the principal application being the Portal. 

The document repository can reside on the same app-server installation as the Portal, or on a different application server or an entirely different physical server.

## Services

The Gawati Data servies are primarily provided in XML format.

## Service Namespaces

Document information is returned in a Gawati XML envelop which has its own namespace:

```
http://gawati.org/ns/1.0/data
```
This is returned with the `gwd` prefix.

```xml
<gwd:docs xmlns:gwd="http://gawati.org/ns/1.0/data" timestamp="2017-07-27T11:42:02.796+05:30" orderedby="dt-updated-desc">
    <gwd:summary work-iri="/akn/ke/act/1989-12-15/CAP16/main" expr-iri="/akn/ke/act/1989-12-15/CAP16/eng@2009-07-23/main"/>
    (...)
</gwd:docs>

```

Full documents are returned in the envelop but with the Akoma Ntoso namespace.


