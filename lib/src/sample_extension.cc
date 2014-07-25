#include <string.h>
#include <stdlib.h>
#include <stdio.h>

#ifdef _WIN32
#include "windows.h"
#else
#include <stdbool.h>
#include <dlfcn.h>
#include <unistd.h>
#include <sys/mman.h>
#endif

#include "dart_api.h"

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope);

DART_EXPORT Dart_Handle sample_extension_Init(Dart_Handle parent_library) {  
  if (Dart_IsError(parent_library)) { return parent_library; }

  Dart_Handle result_code = Dart_SetNativeResolver(parent_library, ResolveName, NULL);
  if (Dart_IsError(result_code)) return result_code;

  return Dart_Null();
}

Dart_Handle HandleError(Dart_Handle handle) {
  if (Dart_IsError(handle)) Dart_PropagateError(handle);
  return handle;
}

void CreateStream(Dart_NativeArguments arguments) {
  Dart_Handle collection; 
  Dart_Handle library_async;
  Dart_Handle library_core;  
  Dart_Handle result;  
  Dart_Handle stream;  
  Dart_Handle type_int;
  Dart_Handle type_stream;
  Dart_Handle url_async;
  Dart_Handle url_core;
  
  Dart_EnterScope();
  collection = Dart_GetNativeArgument(arguments, 0);      
  url_async = Dart_NewStringFromCString("dart:async");
  url_core = Dart_NewStringFromCString("dart:core");  
  library_async = Dart_LookupLibrary(url_async);
  library_core = Dart_LookupLibrary(url_core);      
  type_int = Dart_GetType(library_core, Dart_NewStringFromCString("int"), 0, NULL);  
  type_stream = Dart_GetType(library_core, Dart_NewStringFromCString("Stream"), 0, NULL);
  stream = Dart_New(type_stream, Dart_NewStringFromCString("fromIterable"), 1, &collection);    
  Dart_SetReturnValue(arguments, stream);
  Dart_ExitScope();
}

struct FunctionLookup {
  const char* name;
  Dart_NativeFunction function;
};

FunctionLookup function_list[] = {
  {"CreateStream", CreateStream},  
  {NULL, NULL}};

Dart_NativeFunction ResolveName(Dart_Handle name, int argc, bool* auto_setup_scope) {
  if (!Dart_IsString(name)) return NULL;
  Dart_NativeFunction result = NULL;
  Dart_EnterScope();
  const char* cname;
  HandleError(Dart_StringToCString(name, &cname));

  for (int i=0; function_list[i].name != NULL; ++i) {
    if (strcmp(function_list[i].name, cname) == 0) {
      result = function_list[i].function;
      break;
    }
  }
  Dart_ExitScope();
  return result;
}
