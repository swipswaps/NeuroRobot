//
//  Created by Djordje Jovic on 11/5/18.
//  Copyright � 2018 Backyard Brains. All rights reserved.
//

#include <iostream>

#include "SharedStruct.h"

// Boost includes
#include <boost/lambda/bind.hpp>
#include <boost/lambda/lambda.hpp>
#include <boost/asio.hpp>
#include <boost/algorithm/string.hpp>


using boost::asio::ip::tcp;
using boost::asio::deadline_timer;
using boost::lambda::bind;
using boost::lambda::var;


//----------------------------------------------------------------------

//
// This class manages socket timeouts by applying the concept of a deadline.
// Each asynchronous operation is given a deadline by which it must complete.
// Deadlines are enforced by an "actor" that persists for the lifetime of the
// client object:
//
//  +----------------+
//  |                |
//  | check_deadline |<---+
//  |                |    |
//  +----------------+    | async_wait()
//              |         |
//              +---------+
//
// If the actor determines that the deadline has expired, the socket is closed
// and any outstanding operations are consequently cancelled. The socket
// operations themselves use boost::lambda function objects as completion
// handlers. For a given socket operation, the client object runs the
// io_service to block thread execution until the actor completes.
//
#ifdef DEBUG
#include <fstream>
#include <ctime>
#include <chrono>
#endif

class SocketClient
{
private:
    
    boost::asio::io_service io_service_;
    tcp::socket socket_;
    deadline_timer deadline_;
    boost::asio::streambuf input_buffer_;
    
    
    #ifdef DEBUG
    std::ofstream logFile;
    #endif
    
    
    void openStreams() {
        #ifdef DEBUG
            logFile.open ("logFile_SocketClient.txt");
        #endif
    }
    void closeStreams() {
        #ifdef DEBUG
            logMessage("closeStreams >>> closed");
            logFile.close();
        #endif
    }
    
    void logMessage(std::string message) {
        #ifdef DEBUG
            std::time_t end_time = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
            std::string t(std::ctime(&end_time));
            logFile << t.substr( 0, t.length() -1) << " : " << message << std::endl;
            std::cout << message << std::endl;
        #endif
    }
    
public:
    SocketClient() : socket_(io_service_), deadline_(io_service_)
    {
        openStreams();
        // No deadline is required until the first socket operation is started. We
        // set the deadline to positive infinity so that the actor takes no action
        // until a specific deadline is set.
        deadline_.expires_at(boost::posix_time::pos_infin);
        
        // Start the persistent actor that checks for deadline expiry.
        check_deadline();
    }
    ~SocketClient()
    {
        closeStreams();
    }
    
    void connect(const std::string& host, const std::string& service,
                 boost::posix_time::time_duration timeout)
    {
        boost::system::error_code ec;
        boost::asio::io_context io_context;
        tcp::resolver resolver(io_context);
        boost::asio::connect(socket_, resolver.resolve(host, service), ec);
        
//         Resolve the host name and service to a list of endpoints.
//         tcp::resolver::query query(host, service);
//         tcp::resolver::iterator iter = tcp::resolver(io_service_).resolve(query);
//         
//         Set a deadline for the asynchronous operation. As a host name may
//         resolve to multiple endpoints, this function uses the composed operation
//         async_connect. The deadline applies to the entire operation, rather than
//         individual connection attempts.
//         deadline_.expires_from_now(timeout);
//         
//         Set up the variable that receives the result of the asynchronous
//         operation. The error code is set to would_block to signal that the
//         operation is incomplete. Asio guarantees that its asynchronous
//         operations will never fail with would_block, so any other value in
//         ec indicates completion.
//         boost::system::error_code ec = boost::asio::error::would_block;
//         
//         Start the asynchronous operation itself. The boost::lambda function
//         object is used as a callback and will update the ec variable when the
//         operation completes. The blocking_udp_client.cpp example shows how you
//         can use boost::bind rather than boost::lambda.
//         boost::asio::async_connect(socket_, iter, var(ec) = boost::lambda::_1);
//         
//         Block until the asynchronous operation has completed.
//         do io_service_.run_one(); while (ec == boost::asio::error::would_block);
//         
//         Determine whether a connection was successfully established. The
//         deadline actor may have had a chance to run and close our socket, even
//         though the connect operation notionally succeeded. Therefore we must
//         check whether the socket is still open before deciding if we succeeded
//         or failed.
//         if (ec || !socket_.is_open())
//             throw boost::system::system_error(
//                                               ec ? ec : boost::asio::error::operation_aborted);
        
//         boost::asio::socket_base::keep_alive option(true);
//         socket_.set_option(option);
    }
    
    std::string read_line(boost::posix_time::time_duration timeout)
    {
        logMessage("read_line");
        // Set a deadline for the asynchronous operation. Since this function uses
        // a composed operation (async_read_until), the deadline applies to the
        // entire operation, rather than individual reads from the socket.
        deadline_.expires_from_now(timeout);
        
        // Set up the variable that receives the result of the asynchronous
        // operation. The error code is set to would_block to signal that the
        // operation is incomplete. Asio guarantees that its asynchronous
        // operations will never fail with would_block, so any other value in
        // ec indicates completion.
        boost::system::error_code ec = boost::asio::error::would_block;
        
        // Start the asynchronous operation itself. The boost::lambda function
        // object is used as a callback and will update the ec variable when the
        // operation completes. The blocking_udp_client.cpp example shows how you
        // can use boost::bind rather than boost::lambda.
        boost::asio::async_read_until(socket_, input_buffer_, '\n', var(ec) = boost::lambda::_1);
        
        logMessage("read_line >>> before do");
        // Block until the asynchronous operation has completed.
        do io_service_.run_one(); while (ec == boost::asio::error::would_block);
        logMessage("read_line >>> passed do");
//        if (ec)
//            throw boost::system::system_error(ec);
        
        std::string line;
        std::istream is(&input_buffer_);
        std::getline(is, line);
        logMessage("read_line >>> return line");
        return line;
    }
    
    void write_line(const std::string& line,
                    boost::posix_time::time_duration timeout)
    {
        std::string data = line + "\n";
        
        // Set a deadline for the asynchronous operation. Since this function uses
        // a composed operation (async_write), the deadline applies to the entire
        // operation, rather than individual writes to the socket.
        deadline_.expires_from_now(timeout);
        
        // Set up the variable that receives the result of the asynchronous
        // operation. The error code is set to would_block to signal that the
        // operation is incomplete. Asio guarantees that its asynchronous
        // operations will never fail with would_block, so any other value in
        // ec indicates completion.
        boost::system::error_code ec = boost::asio::error::would_block;
        
        // Start the asynchronous operation itself. The boost::lambda function
        // object is used as a callback and will update the ec variable when the
        // operation completes. The blocking_udp_client.cpp example shows how you
        // can use boost::bind rather than boost::lambda.
        boost::asio::async_write(socket_, boost::asio::buffer(data), var(ec) = boost::lambda::_1);
        
        // Block until the asynchronous operation has completed.
        do io_service_.run_one(); while (ec == boost::asio::error::would_block);
        
        if (ec)
            throw boost::system::system_error(ec);
    }
    size_t send(const void *data, size_t length)
    {
        boost::system::error_code ec;
        size_t sentSize = boost::asio::write(socket_, boost::asio::buffer(data, length), ec);
        return sentSize;
    }
    uint8_t * receiveSerial(boost::system::error_code *ec, size_t *size)
    {
        size_t readSize;
        
        boost::asio::streambuf b;
        readSize = boost::asio::read_until(socket_, b, '\n', *ec);
        std::istream is(&b);
        std::string data;
        std::getline(is, data);
        
        boost::erase_all(data, "\x01U");
        readSize = data.size();
        
        std::memcpy(size, &readSize, sizeof(size_t));
        

        char *replyData = (char *) malloc(readSize);
        data.copy(replyData, readSize);
        return (uint8_t *)replyData;
    }
    
    void close()
    {
        socket_.close();
    }
    
    
    
private:
    void check_deadline()
    {
        // Check whether the deadline has passed. We compare the deadline against
        // the current time since a new asynchronous operation may have moved the
        // deadline before this actor had a chance to run.
        logMessage("check_deadline");
        if (deadline_.expires_at() <= deadline_timer::traits_type::now())
        {
            logMessage("check_deadline -> passed");
            // The deadline has passed. The socket is closed so that any outstanding
            // asynchronous operations are cancelled. This allows the blocked
            // connect(), read_line() or write_line() functions to return.
            boost::system::error_code ignored_ec;
//            socket_.close();
//             logMessage("check_deadline >>> close");
            
            // There is no longer an active deadline. The expiry is set to positive
            // infinity so that the actor takes no action until a new deadline is set.
            deadline_.expires_at(boost::posix_time::pos_infin);
            logMessage("check_deadline >>> expiry");
        }
        
        // Put the actor back to sleep.
        deadline_.async_wait(bind(&SocketClient::check_deadline, this));
        logMessage("check_deadline >>> async_wait");
    }
};
