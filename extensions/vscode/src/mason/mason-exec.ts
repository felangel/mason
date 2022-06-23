import * as vscode from "vscode";
import { isMasonInstalled } from ".";
import { exec, ExecOptions } from "../utils";

let _terminal: vscode.Terminal | undefined;

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

export const masonSpawn = async (cmd: string) => {
  const masonInstalled = await isMasonInstalled();
  if (!masonInstalled) {
    showMissingInstallationWarning();
    return;
  }

  _terminal?.dispose();
  _terminal = vscode.window.createTerminal("mason");

  _terminal.show();
  _terminal.sendText(`mason ${cmd}`);
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
