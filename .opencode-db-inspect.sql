SELECT 'conversations', count(*) FROM conversations;
SELECT 'duplicate_pairs', count(*)
FROM (
  SELECT group_id, user_id
  FROM conversations
  GROUP BY group_id, user_id
  HAVING count(*) > 1
) duplicate_pairs;
SELECT 'constraint', conname, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE conrelid = 'conversations'::regclass
ORDER BY conname;
