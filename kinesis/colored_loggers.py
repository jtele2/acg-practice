"""
TODO: 
  - 01MAR24: For some reason does not work for the info log level, only debug.
"""

import json
import logging
import os


class PersistentDynamicColorFormatter(logging.Formatter):
    storage_file = "logger_colors.json"
    # A set of predefined, easily distinguishable colors.
    distinct_colors = [
        "\033[31m",  # Red
        "\033[32m",  # Green
        "\033[33m",  # Yellow
        "\033[34m",  # Blue
        "\033[35m",  # Magenta
        "\033[36m",  # Cyan
        "\033[91m",  # Light Red
        "\033[92m",  # Light Green
        "\033[93m",  # Light Yellow
        "\033[94m",  # Light Blue
        "\033[95m",  # Light Magenta
        "\033[96m",  # Light Cyan
        "\033[37m",  # White
        "\033[97m",  # Bright White
        "\033[90m",  # Bright Black (Gray)
        "\033[30m",  # Black
        "\033[38;5;208m",  # Orange
        "\033[38;5;202m",  # Red Orange
        "\033[38;5;214m",  # Yellow Orange
        "\033[38;5;226m",  # Bright Yellow
        "\033[38;5;10m",  # Bright Green
        "\033[38;5;46m",  # Sea Green
        "\033[38;5;14m",  # Bright Cyan
        "\033[38;5;49m",  # Dark Cyan
        "\033[38;5;27m",  # Deep Blue
        "\033[38;5;21m",  # Royal Blue
        "\033[38;5;57m",  # Neon Blue
        "\033[38;5;93m",  # Purple
        "\033[38;5;201m",  # Bright Magenta
        "\033[38;5;198m",  # Bright Pink
        "\033[38;5;163m",  # Medium Pink
        "\033[38;5;129m",  # Lavender
        "\033[38;5;165m",  # Peach
        "\033[38;5;9m",  # Darker Red
        "\033[38;5;161m",  # Dark Magenta
        "\033[38;5;13m",  # Medium Magenta
        "\033[38;5;221m",  # Light Gold
        "\033[38;5;178m",  # Light Brown
        "\033[38;5;3m",  # Olive
        "\033[38;5;11m",  # Dark Yellow
        "\033[38;5;19m",  # Navy Blue
        "\033[38;5;141m",  # Light Lavender
        "\033[38;5;171m",  # Sky Blue
        "\033[38;5;123m",  # Light Blue
        "\033[38;5;159m",  # Light Cyan
        "\033[38;5;105m",  # Soft Purple
        "\033[38;5;69m",  # Turquoise
        "\033[38;5;150m",  # Aqua
        "\033[38;5;85m",  # Medium Blue
        "\033[38;5;39m",  # Dark Cyan
    ]

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.load_colors()

    def load_colors(self):
        if os.path.exists(self.storage_file):
            with open(self.storage_file, "r") as file:
                self.logger_colors = json.load(file)
        else:
            self.logger_colors = {}

    def save_colors(self):
        with open(self.storage_file, "w") as file:
            json.dump(self.logger_colors, file)

    def format(self, record):
        if record.name not in self.logger_colors:
            # Cycle through the distinct colors list as needed
            color_index = len(self.logger_colors) % len(self.distinct_colors)
            self.logger_colors[record.name] = self.distinct_colors[color_index]
            self.save_colors()

        color_code = self.logger_colors[record.name]
        formatted_message = super().format(record)
        colored_message = f"{color_code}{formatted_message}\033[0m"
        return colored_message
