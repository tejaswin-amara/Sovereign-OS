package cmd

import (
	"fmt"
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"go.uber.org/zap"
)

var rootCmd = &cobra.Command{
	Use:   "sovereign",
	Short: "Sovereign-OS CLI",
	Long:  `The core orchestrator for Sovereign-OS, built with Cobra, Viper, Zap, and Zerolog.`,
	Run: func(cmd *cobra.Command, args []string) {
		// Zap production logger
		logger, _ := zap.NewProduction()
		defer logger.Sync()
		logger.Info("Sovereign-OS engine initialized (Zap)")

		// Zerolog event streaming logger
		zerolog.TimeFieldFormat = zerolog.TimeFormatUnix
		log.Info().Str("module", "sovereign-cli").Msg("Sovereign-OS event streaming initialized (Zerolog)")

		fmt.Println("Sovereign-OS CLI running. Use --help to see available commands.")
	},
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	cobra.OnInitialize(initConfig)
}

func initConfig() {
	viper.SetConfigFile("sovereign.config.json")
	viper.AddConfigPath(".")
	viper.AutomaticEnv()
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	}
}
