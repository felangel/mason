import * as vscode from "vscode";
import { onFileSaved } from "./events";
import { isMasonInstalled } from "./mason";

export async function activate(context: vscode.ExtensionContext) {
  const masonInstalled = await isMasonInstalled();
  if (!masonInstalled) return showMissingInstallationWarning();

  context.subscriptions.push(
    vscode.workspace.onDidSaveTextDocument(onFileSaved)
  );
}

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
