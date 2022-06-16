import * as _ from "lodash";
import * as vscode from "vscode";
import { masonExec, statusBarTimeout } from ".";

export const masonRemove = async ({
  cwd,
  brick,
  global = false,
}: {
  cwd: string;
  brick: string;
  global?: boolean;
}): Promise<void> => {
  return vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Window,
      title: `mason remove${global ? " -g " : " "}${brick}`,
    },
    async (__) => {
      const document = vscode.window.activeTextEditor?.document;
      if (_.isNil(document)) {
        return;
      }

      try {
        await masonExec(`remove${global ? " -g " : " "}${brick}`, {
          cwd: cwd,
        });
        vscode.window.setStatusBarMessage(
          `✓ mason remove${global ? " -g " : " "}${brick}`,
          statusBarTimeout
        );
      } catch (err) {
        vscode.window.showErrorMessage(`${err}`);
      }
    }
  );
};
