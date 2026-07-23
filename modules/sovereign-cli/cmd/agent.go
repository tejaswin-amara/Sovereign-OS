package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	"github.com/kunchenguid/no-mistakes/internal/ipc"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

func getSocketPath() string {
	if runtime.GOOS == "windows" {
		return `\\.\pipe\SovereignOSLock`
	}
	return filepath.Join(os.TempDir(), "sovereign-os.sock")
}

var agentCmd = &cobra.Command{
	Use:   "agent",
	Short: "Manage and orchestrate agents",
	Long:  `Run, park, or resume AI agents inside the Sovereign-OS daemon.`,
	Run: func(cmd *cobra.Command, args []string) {
		logger, _ := zap.NewProduction()
		defer logger.Sync()

		logger.Info("Agent orchestration invoked (Zap)")

		socketPath := getSocketPath()
		client, err := ipc.Dial(socketPath)
		if err != nil {
			logger.Error("Failed to dial daemon socket", zap.Error(err), zap.String("socket", socketPath))
			fmt.Println("Error: Daemon is offline or unreachable.")
			os.Exit(1)
		}
		defer client.Close()

		var result map[string]interface{}
		if err := client.Call("Agent.Run", args, &result); err != nil {
			logger.Error("RPC Call Failed", zap.Error(err))
			os.Exit(1)
		}

		fmt.Printf("Agent dispatched successfully. ID: %v\n", result["id"])
	},
}

func init() {
	rootCmd.AddCommand(agentCmd)
}
