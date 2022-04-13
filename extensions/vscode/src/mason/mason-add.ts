import * as path from "path";
import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonAdd = async ({
  brick,
  global = false,
}: {
  brick: string;
  global?: boolean;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: "mason add",
    },
    async (_) => {
      const document = vscode.window.activeTextEditor?.document;
      if (!document) return;
      try {
        await masonExec(`add ${global ? "-g" : ""} ${brick}`, {
          cwd: path.join(document.uri.fsPath, ".."),
        });
        vscode.window.setStatusBarMessage(
          `✓ mason add ${global ? "-g" : ""} ${brick}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};
