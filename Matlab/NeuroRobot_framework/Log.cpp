//
//  Created by Djordje Jovic on 5/16/19.
//  Copyright © 2019 Backyard Brains. All rights reserved.
//

#ifndef _Log_cpp
#define _Log_cpp

#include "Log.h"
#include <iostream>

#ifdef DEBUG
    #include <ctime>
    #include <chrono>
    #include <typeinfo>
    #include <string>
    #include <sstream>
    #include <boost/filesystem.hpp>
    #include <iomanip>
#endif


static std::string path;


void createLogsDirectory();
std::string getDate();


Log::~Log()
{
    closeLogFile();
}

void Log::openLogFile() {
#ifdef DEBUG
    createLogsDirectory();
    
    char logFileName[100];
    strcpy(logFileName, path.c_str());
    strcat(logFileName, "/NeuroRobot_logFile_");
    strcat(logFileName, className.c_str());
    strcat(logFileName, ".txt");
    
    logFile.open(logFileName);
    
    logMessage("openLogFile >> path: >> " + std::string(logFileName) + " >>> opened");
#endif
}

void Log::closeLogFile() {
#ifdef DEBUG
    logMessage("closeLogFile >> " + className + " >>> closed");
    if (logFile.is_open()) {
        logFile.close();
    }
#endif
}

void Log::logMessage(std::string message) {
#ifdef DEBUG
    std::time_t now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    std::string t(std::ctime(&now));
    logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
    std::cout << message << std::endl;
#endif
}

void createLogsDirectory() {
#ifdef DEBUG
    int counter = 1;
    boost::filesystem::path dir;
    
    if (!boost::filesystem::exists("Logs")) {
        boost::filesystem::create_directory("Logs");
    }
    
    if (path.empty()) {
        auto date = getDate();
        
        do {
            path = "Logs/" + date + "(" + std::to_string(counter) + ")";
            dir = boost::filesystem::path(path);
            counter++;
            
        } while (boost::filesystem::exists(dir));
        boost::filesystem::create_directory(dir);
    }
#endif
}

std::string getDate() {
#ifdef DEBUG
    std::stringstream ss;
    std::time_t now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
    ss << std::put_time(localtime(&now), "%F_%H-%M-%S");
    return ss.str();
#else
    return "";
#endif
}

#endif // ! _Log_cpp
