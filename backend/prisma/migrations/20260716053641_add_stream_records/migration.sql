-- CreateTable
CREATE TABLE "stream_records" (
    "id" TEXT NOT NULL,
    "song_id" TEXT NOT NULL,
    "user_id" TEXT,
    "owner_id" TEXT NOT NULL,
    "ip" TEXT,
    "user_agent" TEXT,
    "country" TEXT,
    "city" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "stream_records_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "stream_records_owner_id_created_at_idx" ON "stream_records"("owner_id", "created_at");

-- CreateIndex
CREATE INDEX "stream_records_song_id_created_at_idx" ON "stream_records"("song_id", "created_at");

-- CreateIndex
CREATE INDEX "stream_records_created_at_idx" ON "stream_records"("created_at");

-- AddForeignKey
ALTER TABLE "stream_records" ADD CONSTRAINT "stream_records_song_id_fkey" FOREIGN KEY ("song_id") REFERENCES "songs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stream_records" ADD CONSTRAINT "stream_records_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
