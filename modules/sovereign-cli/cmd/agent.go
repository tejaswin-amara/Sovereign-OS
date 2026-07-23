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
	RunE: func(cmd *cobra.Command, args []string) error {
		logger, err := zap.NewProduction()
		if err != nil {
			return fmt.Errorf("failed to initialize logger: %w", err)
		}
		defer func() { _ = logger.Sync() }()

		logger.Info("Agent orchestration invoked (Zap)")

		socketPath := getSocketPath()
		client, err := ipc.Dial(socketPath)
		if err != nil {
			logger.Error("Failed to dial daemon socket", zap.Error(err), zap.String("socket", socketPath))
			return fmt.Errorf("error: daemon is offline or unreachable (%w)", err)
		}
		defer client.Close()

		var result map[string]interface{}
		if err := client.Call("Agent.Run", args, &result); err != nil {
			logger.Error("RPC Call Failed", zap.Error(err))
			return fmt.Errorf("rpc call failed: %w", err)
		}

		fmt.Printf("Agent dispatched successfully. ID: %v\n", result["id"])
		return nil
	},
}

func init() {
	rootCmd.AddCommand(agentCmd)
}
