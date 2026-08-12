import type { CommunityPost } from "~/api/community-posts";

const MENTION_PATTERN = /\{\{mention:(\d+)\}\}/g;

export function resolveCommunityPostBody(
  post: Pick<CommunityPost, "body" | "mention_users">
): string {
  return post.body.replace(MENTION_PATTERN, (token, indexValue: string) => {
    const mention = post.mention_users[Number(indexValue)];
    return mention ? `@${mention.username}` : token;
  });
}
