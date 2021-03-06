
/* Client for IHello
 * Heavily modified from:
 */
/*
 * SELFREG.CPP
 * Server Self-Registrtation Utility, Chapter 5
 *
 * Copyright (c)1993-1995 Microsoft Corporation, All Rights Reserved
 *
 * Kraig Brockschmidt, Microsoft
 * Internet  :  kraigb@microsoft.com
 * Compuserve:  >INTERNET:kraigb@microsoft.com
 */

import std.c.stdio;
import std.c.stdlib;
import std.c.windows.windows;
import std.c.windows.com;

GUID CLSID_Hello = { 0x30421140, 0, 0, [0xC0, 0, 0, 0, 0, 0, 0, 0x46] };
GUID IID_IHello = { 0x00421140, 0, 0, [0xC0, 0, 0, 0, 0, 0, 0, 0x46] };

interface IHello : IUnknown
{
    extern (Windows) :
    int Print();
}

int main()
{
    DWORD dwVer;
    HRESULT hr;
    IHello  pIHello;

    // Make sure COM is the right version
    dwVer = CoBuildVersion();

    if (rmm != HIWORD(dwVer))
    {
    printf("Incorrect OLE 2 version number\n");
    return EXIT_FAILURE;
    }

    hr=CoInitialize(null);              // Initialize OLE

    if (FAILED(hr))
    {
        printf("OLE 2 failed to initialize\n");
        return EXIT_FAILURE;
    }

    printf("OLE 2 initialized\n");

    if (dll_regserver("dserver.dll", 1) == 0)
    {
        printf("server registered\n");
        hr=CoCreateInstance(&CLSID_Hello, null, CLSCTX_ALL, &IID_IHello, &pIHello);

        if (FAILED(hr))
        {
            printf("Failed to create object x%x\n", hr);
        }
        else
        {
            printf("Object created, calling IHello.Print(), IHello = %p\n", pIHello);

            // fflush(stdout);
            pIHello.Print();
            pIHello.Release();
        }

        CoFreeUnusedLibraries();

        if (dll_regserver("dserver.dll", 0))
            printf("server unregister failed\n");
    }
    else
        printf("server registration failed\n");

    // Only call this if CoInitialize worked
    CoUninitialize();
    return EXIT_SUCCESS;
}

/**************************************
 * Register/unregister a DLL server.
 * Input:
 *      flag    !=0: register
 *              ==0: unregister
 * Returns:
 *      0       success
 *      !=0     failure
 */

extern (Windows) alias HRESULT (*pfn_t)();

int dll_regserver(const (char) *dllname, int flag)
{
    char *fn = flag ? cast(char*) "DllRegisterServer"
               : cast(char*) "DllUnregisterServer";
    int result = 1;
    pfn_t pfn;
    HINSTANCE hMod;

    if (SUCCEEDED(CoInitialize(null)))
    {
        hMod=LoadLibraryA(dllname);
        printf("hMod = %d\n", hMod);

        if (hMod > cast(HINSTANCE) HINSTANCE_ERROR)
        {
            printf("LoadLibraryA() succeeded\n");
            pfn = GetProcAddress(hMod, fn);
            printf("pfn = %p, fn = '%s'\n", pfn, fn);

            if (pfn && SUCCEEDED((*pfn)()))
                result = 0;

            CoFreeLibrary(hMod);
            CoUninitialize();
        }
    }

    return result;
}
