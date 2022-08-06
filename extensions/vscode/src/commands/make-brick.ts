import * as _ from "lodash";
import { existsSync, lstatSync, readFileSync } from "fs";
import * as path from "path";
import * as vscode from "vscode";
import { Uri, window } from "vscode";
import { getBrickYaml, masonMake } from "../mason";
import { env, platform } from "node:process";

export const makeLocalBrick = async (uri: Uri) => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

  if (_.isNil(cwd)) {
    return;
  }

  let targetDirectory;

  if (_.isNil(_.get(uri, "fsPath")) || !lstatSync(uri.fsPath).isDirectory()) {
    targetDirectory = await promptForTargetDirectory();
    if (_.isNil(targetDirectory)) {
      window.showErrorMessage("Please select a valid directory");
      return;
    }
  } else {
    targetDirectory = uri.fsPath;
  }

  const bricksJson = await getBricksJson({ cwd });

  if (_.isNil(bricksJson)) {
    window.showErrorMessage("No bricks found in the workspace");
    return;
  }

  const bricks = Object.keys(bricksJson);
  const brickName = await promptForBrickName({ bricks });

  if (_.isNil(brickName)) {
    window.showErrorMessage("No brick selected");
    return;
  }

  const brickPath = bricksJson[brickName];
  const brickYaml = await getBrickYaml({ brickPath });

  if (_.isNil(brickYaml)) {
    window.showErrorMessage("Could not read brick.yaml");
    return;
  }

  const name: string = brickYaml.name;

  let vars: string[] = [];
  for (let key in brickYaml.vars) {
    const value = await promptForValue(brickYaml.vars[key]);
    if (_.isNil(value)) {
      return;
    }
    vars.push(`--${key} ${value.toString()}`);
  }
  const args = vars.join(" ");

  await masonMake({ targetDirectory, name, args });
};

export const makeGlobalBrick = async (uri: Uri) => {
  const cwd = vscode.workspace.workspaceFolders?.[0].uri.fsPath;

  if (_.isNil(cwd)) {
    return;
  }

  let targetDirectory;

  if (_.isNil(_.get(uri, "fsPath")) || !lstatSync(uri.fsPath).isDirectory()) {
    targetDirectory = await promptForTargetDirectory();
    if (_.isNil(targetDirectory)) {
      window.showErrorMessage("Please select a valid directory");
      return;
    }
  } else {
    targetDirectory = uri.fsPath;
  }

  const rootDir = _rootDir();
  const globalDir = path.join(rootDir, "global");
  const bricksJson = await getBricksJson({ cwd: globalDir });

  if (_.isNil(bricksJson)) {
    window.showErrorMessage("No global bricks found");
    return;
  }

  const bricks = Object.keys(bricksJson);
  const brickName = await promptForBrickName({ bricks });

  if (_.isNil(brickName)) {
    window.showErrorMessage("No brick selected");
    return;
  }

  const brickPath = bricksJson[brickName];
  const brickYaml = await getBrickYaml({ brickPath });

  if (_.isNil(brickYaml)) {
    window.showErrorMessage("Could not read brick.yaml");
    return;
  }

  const name: string = brickYaml.name;

  let vars: string[] = [];
  for (let key in brickYaml.vars) {
    const value = await promptForValue(brickYaml.vars[key]);
    if (_.isNil(value)) {
      return;
    }
    vars.push(`--${key} ${value.toString()}`);
  }
  const args = vars.join(" ");

  await masonMake({ targetDirectory, name, args });
};

const promptForBrickName = ({ bricks }: { bricks: string[] }) => {
  return vscode.window.showQuickPick(bricks, {
    canPickMany: false,
    matchOnDescription: true,
    placeHolder: `Pick a brick`,
  });
};

const getBricksJson = async ({
  cwd,
}: {
  cwd: string;
}): Promise<Record<string, any> | undefined> => {
  const bricksJsonPath = path.join(cwd, ".mason", "bricks.json");
  if (!existsSync(bricksJsonPath)) {
    return undefined;
  }
  const bricksJson = JSON.parse(
    readFileSync(bricksJsonPath, { encoding: "utf-8" })
  );
  return bricksJson;
};

const promptForValue = async (args: any): Promise<string | undefined> => {
  if (args.type === "string" || args.type === "number") {
    return promptForPrimitive(args.prompt, args.default);
  }
  if (args.type === "boolean") {
    return promptForBoolean(args.prompt, args.default);
  }
  if (args.type === "enum") {
    return promptForEnum(args.prompt, args.default, args.values);
  }
  if (args.type === "array") {
    return promptForArray(args.prompt, args.defaults, args.values);
  }
  window.showInformationMessage(`${args.type} type is not supported.`);
  if (args.default) {
    return args.default.toString();
  }
  if (args.defaults) {
    return args.defaults.toString();
  }
  window.showErrorMessage(`Could not find a default value for ${args.name}.`);
  return;
};

const promptForPrimitive = async (
  title: string,
  _default: string
): Promise<string | undefined> => {
  let result = await vscode.window.showInputBox({
    placeHolder: _default,
    prompt: title,
  });
  if (result === "") {
    return _default;
  }
  if (result?.includes(" ")) {
    return `"${result}"`;
  }
  return result;
};

const promptForBoolean = async (
  title: string,
  _default: boolean
): Promise<string | undefined> => {
  const items = [_default.toString(), (!_default).toString()];
  return vscode.window.showQuickPick(items, {
    canPickMany: false,
    placeHolder: title,
  });
};

const promptForEnum = async (
  title: string,
  _default: string,
  items: string[]
): Promise<string | undefined> => {
  if (_.isNil(_default) && !_.isEmpty(items)) {
    _default = items[0];
  }

  return vscode.window.showQuickPick(
    [_default, ...items.filter((item) => item !== _default)],
    {
      canPickMany: false,
      placeHolder: title,
    }
  );
};

const promptForArray = async (
  title: string,
  _default: string[],
  items: string[]
): Promise<string | undefined> => {
  const options: vscode.QuickPickItem[] = items.map((item) => ({
    label: item,
    picked: _default.includes(item),
  }));
  const results = await vscode.window.showQuickPick(options, {
    canPickMany: true,
    placeHolder: title,
  });
  const selections = results?.map((r) => r.label);
  return JSON.stringify(JSON.stringify(selections));
};

async function promptForTargetDirectory(): Promise<string | undefined> {
  const options: vscode.OpenDialogOptions = {
    canSelectMany: false,
    openLabel: "Select a folder",
    canSelectFolders: true,
  };

  return window.showOpenDialog(options).then((uri) => {
    if (_.isNil(uri) || _.isEmpty(uri)) {
      return undefined;
    }
    return uri[0].fsPath;
  });
}

function _rootDir(): string {
  const masonCache = env["MASON_CACHE"];
  if (!_.isNil(masonCache)) {
    return masonCache;
  }
  const isWindows = platform === "win32";
  if (isWindows) {
    const appData = env["APPDATA"]!;
    const appDataCacheDir = path.join(appData, "Mason", "Cache");
    if (existsSync(appDataCacheDir)) {
      return appDataCacheDir;
    }
    const localAppData = env["LOCALAPPDATA"]!;
    return path.join(localAppData, "Mason", "Cache");
  } else {
    return path.join(env["HOME"]!, ".mason-cache");
  }
}
