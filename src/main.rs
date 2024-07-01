use std::{
    io::{BufRead, BufReader, Read, Write},
    net::{TcpListener, TcpStream},
    process::{Command, Stdio},
    thread,
};

use clap::{Parser, Subcommand};

#[derive(Parser, Debug)]
struct Clap {
    #[clap(subcommand)]
    command: Cmd,
}

#[derive(Subcommand, Debug)]
enum Cmd {
    /// Starts the server
    Server,

    /// Sends a message
    Send {
        /// message to send
        msg: String,
    },
}

fn main() -> anyhow::Result<()> {
    let cli = Clap::parse();
    match cli.command {
        Cmd::Server => {
            listen()?;
        }
        Cmd::Send { msg } => {
            send(&msg)?;
        }
    }

    Ok(())
}

fn listen() -> anyhow::Result<()> {
    let listener = TcpListener::bind("127.0.0.1:7878").unwrap();
    println!("Server listening on port 7878");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                thread::spawn(|| {
                    handle_client(stream);
                });
            }
            Err(e) => {
                println!("Connection failed: {}", e);
            }
        }
    }

    Ok(())
}

fn send(msg: &str) -> anyhow::Result<()> {
    match TcpStream::connect("127.0.0.1:7878") {
        Ok(mut stream) => {
            println!("Successfully connected to server in port 7878");

            stream.write(msg.as_bytes()).unwrap();
            println!("Sent message: {:?}", msg);

            let mut buffer = [0; 512];
            let bytes_read = stream.read(&mut buffer).unwrap();
            println!(
                "Received: {}",
                String::from_utf8_lossy(&buffer[..bytes_read])
            );
        }
        Err(e) => {
            println!("Failed to connect: {}", e);
        }
    }

    Ok(())
}

fn handle_client(mut stream: TcpStream) {
    let mut buffer = [0; 1024];
    let bytes_read = stream.read(&mut buffer).unwrap();

    let cmd = String::from_utf8_lossy(&buffer[..bytes_read]);
    println!("Received: {}", cmd);

    match execute_cmd(&cmd) {
        Ok(res) => res,
        Err(e) => {
            let err_msg = format!("Failed to execute command: {}", e);
            eprintln!("{}", err_msg);
            stream.write(err_msg.as_bytes()).unwrap();
            stream.flush().ok();
            return;
        }
    };

    let response = "OK"; // String::from_utf8_lossy(&output.stdout).to_string();
                         // let error = String::from_utf8_lossy(&output.stderr).to_string();

    stream.write(response.as_bytes()).unwrap();
    stream.flush().ok();
}

fn execute_cmd(cmd: &str) -> anyhow::Result<()> {
    clear_screen();

    let mut child = Command::new("sh")
        .arg("-c")
        .arg(cmd)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("Failed to execute command");

    let stdout = child.stdout.take().expect("Failed to capture stdout");
    let stderr = child.stderr.take().expect("Failed to capture stderr");

    let _stdout_thread = thread::spawn(move || {
        let reader = BufReader::new(stdout);
        for line in reader.lines() {
            match line {
                Ok(line) => println!("{}", line),
                Err(e) => eprintln!("Failed to read stdout: {}", e),
            }
        }
    });

    let _stderr_thread = thread::spawn(move || {
        let buf_reader = BufReader::new(stderr);
        let reader = buf_reader;
        for line in reader.lines() {
            match line {
                Ok(line) => eprintln!("{}", line),
                Err(e) => eprintln!("Failed to read stderr: {}", e),
            }
        }
    });

    let _status = child.wait()?;

    Ok(())
}

fn clear_screen() {
    // ANSI escape code to clear the screen
    print!("\x1B[2J\x1B[1;1H");
    // Flush the stdout to ensure the command is executed immediately
    std::io::stdout().flush().unwrap();
}
