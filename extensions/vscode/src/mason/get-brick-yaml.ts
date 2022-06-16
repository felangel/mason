import * as path from "path";
import * as YAML from "yaml";
import { existsSync, readFileSync } from "fs";

interface BrickYaml {
  name: string;
  vars: Record<string, Object>;
}

export const getBrickYaml = async ({
  brickPath,
}: {
  brickPath: string;
}): Promise<BrickYaml | undefined> => {
  const brickYamlPath = path.join(brickPath, "brick.yaml");
  if (!existsSync(brickYamlPath)) {
    return undefined;
  }
  return YAML.parse(readFileSync(brickYamlPath, { encoding: "utf-8" }));
};
