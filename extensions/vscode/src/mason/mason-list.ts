import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonList = async ({
  cwd,
}: {
  cwd: string;
}): Promise<string> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason list`,
    },
    async (_) => {
      try {
        const list = await masonExec(`list`, {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason list`,
          statusBarTimeout
        );
        if (list) {
          return list;
        } 
        return '';
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
        return '';
      }
    }
  );
};
