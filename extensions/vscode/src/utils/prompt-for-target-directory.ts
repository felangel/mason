import * as _ from "lodash";
import * as vscode from "vscode";

export async function promptForTargetDirectory(): Promise<string | undefined> {
  const options: vscode.OpenDialogOptions = {
    canSelectMany: false,
    openLabel: "Select a folder",
    canSelectFolders: true,
  };

  return vscode.window.showOpenDialog(options).then((uri) => {
    if (_.isNil(uri) || _.isEmpty(uri)) {
      return undefined;
    }
    return uri[0].fsPath;
  });
}
