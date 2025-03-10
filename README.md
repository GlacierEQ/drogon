![](https://github.com/an-tao/drogon/wiki/images/drogon-white17.jpg)

[![Build Status](https://github.com/drogonframework/drogon/actions/workflows/cmake.yml/badge.svg?branch=master)](https://github.com/drogonframework/drogon/actions)
[![Conan Center](https://img.shields.io/conan/v/drogon)](https://conan.io/center/recipes/drogon)
[![Join the telegram group at https://t.me/joinchat/_mMNGv0748ZkMDAx](https://img.shields.io/badge/Telegram-2CA5E0?style=flat&logo=telegram&logoColor=white)](https://t.me/joinchat/_mMNGv0748ZkMDAx)
[![Join our Discord](https://dcbadge.vercel.app/api/server/3DvHY6Ewuj?style=flat)](https://discord.gg/3DvHY6Ewuj)
[![Docker image](https://img.shields.io/badge/Docker-image-blue.svg)](https://cloud.docker.com/u/drogonframework/repository/docker/drogonframework/drogon)

English | [简体中文](./README.zh-CN.md) | [繁體中文](./README.zh-TW.md)
### Overview
**Drogon** is a C++17/20 based HTTP application framework. Drogon can be used to easily build various types of web application server programs using C++. **Drogon** is the name of a dragon from the American TV series *Game of Thrones*, which I really enjoy.

Drogon is a cross-platform framework, It supports Linux, macOS, FreeBSD, OpenBSD, HaikuOS, and Windows. Its main features are as follows:

* Use a non-blocking I/O network lib based on epoll (kqueue under macOS/FreeBSD) to provide high-concurrency, high-performance network IO, please visit the [TFB Tests Results](https://www.techempower.com/benchmarks/#section=data-r19&hw=ph&test=composite) for more details;
* Provide a completely asynchronous programming mode;
* Support Http1.0/1.1 (server side and client side);
* Based on template, a simple reflection mechanism is implemented to completely decouple the main program framework, controllers and views.
* Support cookies and built-in sessions;
* Support back-end rendering, the controller generates the data to the view to generate the Html page. Views are described by CSP template files, C++ codes are embedded into Html pages through CSP tags. And the drogon command-line tool automatically generates the C++ code files for compilation;
* Support view page dynamic loading (dynamic compilation and loading at runtime);
* Provide a convenient and flexible routing solution from the path to the controller handler;
* Support filter chains to facilitate the execution of unified logic (such as login verification, Http Method constraint verification, etc.) before handling HTTP requests;
* Support https (based on OpenSSL);
* Support WebSocket (server side and client side);
* Support JSON format request and response, very friendly to the Restful API application development;
* Support file download and upload;
* Support gzip, brotli compression transmission;
* Support pipelining;
* Provide a lightweight command line tool, drogon_ctl, to simplify the creation of various classes in Drogon and the generation of view code;
* Support non-blocking I/O based asynchronously reading and writing database (PostgreSQL and MySQL(MariaDB) database);
* Support asynchronously reading and writing sqlite3 database based on thread pool;
* Support Redis with asynchronous reading and writing;
* Support ARM Architecture;
* Provide a convenient lightweight ORM implementation that supports for regular object-to-database bidirectional mapping;
* Support plugins which can be installed by the configuration file at load time;
* Support AOP with built-in joinpoints.
* Support C++ coroutines

## A very simple example

Unlike most C++ frameworks, the main program of the drogon application can be kept clean and simple. Drogon uses a few tricks to decouple controllers from the main program. The routing settings of controllers can be done through macros or configuration file.

Below is the main program of a typical drogon application:

```c++
#include <drogon/drogon.h>
using namespace drogon;
int main()
{
    app().setLogPath("./")
         .setLogLevel(trantor::Logger::kWarn)
         .addListener("0.0.0.0", 80)
         .setThreadNum(16)
         .enableRunAsDaemon()
         .run();
}
```

It can be further simplified by using configuration file as follows:

```c++
#include <drogon/drogon.h>
using namespace drogon;
int main()
{
    app().loadConfigFile("./config.json").run();
}
```

Drogon provides some interfaces for adding controller logic directly in the main() function, for example, user can register a handler like this in Drogon:

```c++
app().registerHandler("/test?username={name}",
                    [](const HttpRequestPtr& req,
                       std::function<void (const HttpResponsePtr &)> &&callback,
                       const std::string &name)
                    {
                        Json::Value json;
                        json["result"]="ok";
                        json["message"]=std::string("hello,")+name;
                        auto resp=HttpResponse::newHttpJsonResponse(json);
                        callback(resp);
                    },
                    {Get,"LoginFilter"});
```

While such interfaces look intuitive, they are not suitable for complex business logic scenarios. Assuming there are tens or even hundreds of handlers that need to be registered in the framework, isn't it a better practice to implement them separately in their respective classes? So unless your logic is very simple, we don't recommend using above interfaces. Instead, we can create an HttpSimpleController as follows:

```c++
/// The TestCtrl.h file
#pragma once
#include <drogon/HttpSimpleController.h>
using namespace drogon;
class TestCtrl:public drogon::HttpSimpleController<TestCtrl>
{
public:
    void asyncHandleHttpRequest(const HttpRequestPtr& req, std::function<void (const HttpResponsePtr &)> &&callback) override;
    PATH_LIST_BEGIN
    PATH_ADD("/test",Get);
    PATH_LIST_END
};

/// The TestCtrl.cc file
#include "TestCtrl.h"
void TestCtrl::asyncHandleHttpRequest(const HttpRequestPtr& req,
                                      std::function<void (const HttpResponsePtr &)> &&callback)
{
    //write your application logic here
    auto resp = HttpResponse::newHttpResponse();
    resp->setBody("<p>Hello, world!</p>");
    resp->setExpiredTime(0);
    callback(resp);
}
```

**Most of the above programs can be automatically generated by the command line tool `drogon_ctl` provided by drogon** (The command is `drogon_ctl create controller TestCtrl`). All the user needs to do is add their own business logic. In the example, the controller returns a `Hello, world!` string when the client accesses the `http://ip/test` URL.

For JSON format response, we create the controller as follows:

```c++
/// The header file
#pragma once
#include <drogon/HttpSimpleController.h>
using namespace drogon;
class JsonCtrl : public drogon::HttpSimpleController<JsonCtrl>
{
  public:
    void asyncHandleHttpRequest(const HttpRequestPtr &req, std::function<void(const HttpResponsePtr &)> &&callback) override;
    PATH_LIST_BEGIN
    //list path definitions here;
    PATH_ADD("/json", Get);
    PATH_LIST_END
};

/// The source file
#include "JsonCtrl.h"
void JsonCtrl::asyncHandleHttpRequest(const HttpRequestPtr &req,
                                      std::function<void(const HttpResponsePtr &)> &&callback)
{
    Json::Value ret;
    ret["message"] = "Hello, World!";
    auto resp = HttpResponse::newHttpJsonResponse(ret);
    callback(resp);
}
```

Let's go a step further and create a demo RESTful API with the HttpController class, as shown below (Omit the source file):

```c++
/// The header file
#pragma once
#include <drogon/HttpController.h>
using namespace drogon;
namespace api
{
namespace v1
{
class User : public drogon::HttpController<User>
{
  public:
    METHOD_LIST_BEGIN
    //use METHOD_ADD to add your custom processing function here;
    METHOD_ADD(User::getInfo, "/{id}", Get);                  //path is /api/v1/User/{arg1}
    METHOD_ADD(User::getDetailInfo, "/{id}/detailinfo", Get);  //path is /api/v1/User/{arg1}/detailinfo
    METHOD_ADD(User::newUser, "/{name}", Post);                 //path is /api/v1/User/{arg1}
    METHOD_LIST_END
    //your declaration of processing function maybe like this:
    void getInfo(const HttpRequestPtr &req, std::function<void(const HttpResponsePtr &)> &&callback, int userId) const;
    void getDetailInfo(const HttpRequestPtr &req, std::function<void(const HttpResponsePtr &)> &&callback, int userId) const;
    void newUser(const HttpRequestPtr &req, std::function<void(const HttpResponsePtr &)> &&callback, std::string &&userName);
  public:
    User()
    {
        LOG_DEBUG << "User constructor!";
    }
};
} // namespace v1
} // namespace api
```

As you can see, users can use the `HttpController` to map paths and parameters at the same time. This is a very convenient way to create a RESTful API application.

In addition, you can also find that all handler interfaces are in asynchronous mode, where the response is returned by a callback object. This design is for performance reasons because in asynchronous mode the drogon application can handle a large number of concurrent requests with a small number of threads.

After compiling all of the above source files, we get a very simple web application. This is a good start. **For more information, please visit the [documentation](https://drogonframework.github.io/drogon-docs/#/) on GitHub**.

## Dependencies Management

Drogon provides scripts to help manage all required dependencies and add them to your environment path:

- For Linux/macOS: Run the setup script `./setup_env.sh`
- For Windows: Run the PowerShell script as administrator `.\setup_env.ps1`

These scripts will automatically install all necessary dependencies and configure your environment paths. For manual installation instructions, see [INSTALL_DEPENDENCIES.md](./docs/INSTALL_DEPENDENCIES.md).

## Cross-compilation

Drogon supports cross-compilation, you should define the `CMAKE_SYSTEM_NAME` in toolchain file, for example:
    
```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)
```

You can disable building options for examples and drogon_ctl by settings `BUILD_EXAMPLES` and `BUILD_CTL` to `OFF` in the toolchain file.

## Building options

Drogon provides some building options, you can enable or disable them by setting the corresponding variables to `ON` or `OFF` in the cmake command line, cmake file etc...

| Option name | Description | Default value |
| :--- | :--- | :--- |
| BUILD_CTL | Build drogon_ctl | ON |
| BUILD_EXAMPLES | Build examples | ON |
| BUILD_ORM | Build orm | ON |
| COZ_PROFILING | Use coz for profiling | OFF |
| BUILD_SHARED_LIBS | Build drogon as a shared lib | OFF |
| BUILD_DOC | Build Doxygen documentation | OFF |
| BUILD_BROTLI | Build Brotli | ON |
| BUILD_YAML_CONFIG | Build yaml config | ON |
| USE_SUBMODULE | Use trantor as a submodule | ON |


## Contributions

This project exists thanks to all the people who contribute code. 

<a href="https://github.com/drogonframework/drogon/graphs/contributors"><img src="https://contributors-svg.opencollective.com/drogon/contributors.svg?width=890&button=false" alt="Code contributors" /></a>

Every contribution is welcome. Please refer to the [contribution guidelines](CONTRIBUTING.md) for more information.
