package main

import (
	"io"
	"log"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

const backup = false

func main() {
	startcmd := exec.Command("java", "@user_jvm_args.txt", "@libraries/net/minecraftforge/forge/1.20.1-47.3.33/unix_args.txt", "nogui", "\"$@\"")
	stdinpipe, err := startcmd.StdinPipe()
	if err != nil {
		log.Fatalf("Failed to set stdinpipe: %v", err)
	}
	go io.Copy(stdinpipe, os.Stdin)
	startcmd.Stdout = os.Stdout
	startcmd.Stderr = os.Stderr
	err = startcmd.Start()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			log.Printf("Server returned non-zero code during init: %v", err)
			os.Exit(exitErr.ExitCode())
		} else {
			log.Fatalf("Server failed during init: %v", err)
		}
	}
	waitCh := make(chan int)
	go func() {
		err = startcmd.Wait()
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				log.Printf("Server returned non-zero code after init: %v", err)
				waitCh <- exitErr.ExitCode()
			} else {
				log.Printf("Server failed after init: %v", err)
				waitCh <- 1
			}
		} else {
			waitCh <- 0
		}
	}()
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGTERM)
	exitCode := -1
	select {
	case <-sigCh:
		io.WriteString(stdinpipe, "\nstop\n")
		exitCode = <-waitCh
	case code := <-waitCh:
		exitCode = code
	}
	if backup {
		backupcmd := exec.Command("./backup.sh")
		backupcmd.Stdin = os.Stdin
		backupcmd.Stdout = os.Stdout
		backupcmd.Stderr = os.Stderr
		err = backupcmd.Run()
		if err != nil {
			if exitErr, ok := err.(*exec.ExitError); ok {
				log.Printf("backup.sh returned non-zero code: %v", err)
				if exitCode == 0 {
					exitCode = exitErr.ExitCode()
				}
			} else {
				log.Printf("Failed to run backup.sh: %v", err)
				if exitCode == 0 {
					exitCode = 1
				}
			}
		}
	}
	os.Exit(exitCode)
}
