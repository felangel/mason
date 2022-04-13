import * as vscode from "vscode";
import { isMasonInstalled } from ".";
import { exec, ExecOptions } from "../utils";

export const masonExec = async (cmd: string, options?: ExecOptions) => {
  const masonInstalled = await isMasonInstalled();
  if (!masonInstalled) {
    showMissingInstallationWarning();
    return;
  }

  return exec(`mason ${cmd}`, {
    cwd: options?.cwd,
  });
};

const showMissingInstallationWarning = () => {
  vscode.window
    .showWarningMessage(
      "No mason installation was found.",
      "Open installation instructions"
    )
    .then((_) => {
      if (_) {
        vscode.env.openExternal(
          vscode.Uri.parse(
            "https://github.com/felangel/mason/tree/master/packages/mason_cli#installation"
          )
        );
      }
    });
};
