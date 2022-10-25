/*
    GEOSLib example

    using DlgBoxFileSelect

    Maciej 'YTM/Elysium' Witkowiak
    <ytm@elysium.pl>

    26.12.1999
*/


#include <geos.h>

char fName[17] = "";

void main (void)
{
    r0=(int)fName;

    DlgBoxFileSelect("", APPLICATION, fName);

    GetFile(0, fName, NULL, NULL, NULL);

}
