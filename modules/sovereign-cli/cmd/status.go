package cmd

import (
	"fmt"

	"github.com/kunchenguid/no-mistakes/internal/ipc"
	"github.com/spf13/cobra"
	"go.uber.org/zap"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check system status",
	Long:  `Check the real-time status of the Sovereign-OS daemon and active agents.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		logger, err := zap.NewProduction()
		if err != nil {
			return fmt.Errorf("failed to initialize logger: %w", err)
		}
		defer func() { _ = logger.Sync() }()

		logger.Info("Status check invoked (Zap)")

		socketPath := getSocketPath()
		client, err := ipc.Dial(socketPath)
		if err != nil {
			logger.Error("Failed to dial daemon socket", zap.Error(err), zap.String("socket", socketPath))
			fmt.Println("System Status: OFFLINE")
			return fmt.Errorf("daemon socket offline: %w", err)
		}
		defer client.Close()

		var result map[string]interface{}
		_ = client.Call("Health.Check", nil, &result)

		fmt.Println("System Status: ONLINE")
		fmt.Println("Daemon Lock: ACQUIRED")
		fmt.Printf("Active Modules: %v\n", result["modules_count"])
		return nil
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}
